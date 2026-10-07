# bucket de imagenes, cola SQS + DLQ y notificacion S3 -> SQS

# sufijo aleatorio porque el nombre del bucket tiene que ser unico en todo AWS
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "images" {
  bucket = "${var.name_prefix}-images-${random_id.bucket_suffix.hex}"

  # con versionado el bucket nunca queda vacio y destroy falla, asi que se borra con todo
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  # con versionado la expiracion solo pone un delete marker, la version vieja
  # se borra con noncurrent_version_expiration
  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {
      prefix = var.uploads_prefix
    }

    expiration {
      days = var.uploads_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_expiration_days
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter {
      prefix = var.processed_prefix
    }

    expiration {
      days = var.processed_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_expiration_days
    }
  }

  # la regla de lifecycle necesita el versionado ya activo
  depends_on = [aws_s3_bucket_versioning.images]
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name_prefix}-image-dlq"
  message_retention_seconds = 1209600 # 14 dias, para alcanzar a revisar los mensajes que fallaron
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.name_prefix}-image-queue"
  visibility_timeout_seconds = 6 * var.crop_lambda_timeout # 360 s, lo que recomienda AWS para colas con trigger de Lambda
  message_retention_seconds  = 86400                       # 1 dia
  receive_wait_time_seconds  = 20                          # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# sin esta politica S3 no puede mandar mensajes a la cola y la notificacion falla al crearse
resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3SendMessage"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_s3_bucket.images.arn }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn = aws_sqs_queue.main.arn
    events    = ["s3:ObjectCreated:*"]

    # solo uploads/: si no, cada PNG que crop guarda en processed/ volveria a disparar el recorte
    filter_prefix = var.uploads_prefix
  }

  depends_on = [aws_sqs_queue_policy.main]
}
