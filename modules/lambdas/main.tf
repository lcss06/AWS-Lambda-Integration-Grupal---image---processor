# ---------------------------------------------------------------------------
# Nombres y empaquetado del codigo
# ---------------------------------------------------------------------------

locals {
  upload_name = "${var.name_prefix}-upload"
  crop_name   = "${var.name_prefix}-crop"

  upload_timeout = 30
  crop_timeout   = 60

  # politicas administradas por AWS que necesitan las dos lambdas
  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",    # escribir logs
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole", # crear interfaces de red en la VPC
  ]
}
data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "${var.lambdas_source_dir}/upload"
  output_path = "${path.root}/build/upload.zip"
}

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = "${var.lambdas_source_dir}/crop"
  output_path = "${path.root}/build/crop.zip"
}

# ---------------------------------------------------------------------------
# IAM: un rol por lambda, con el minimo permiso necesario
# ---------------------------------------------------------------------------

# "quien puede usar estos roles": solo el servicio Lambda
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- rol de upload ---
resource "aws_iam_role" "upload" {
  name               = "${local.upload_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_role_policy_attachment" "upload" {
  for_each   = toset(local.managed_policies)
  role       = aws_iam_role.upload.name
  policy_arn = each.value
}

# solo puede escribir en uploads/, nada mas
resource "aws_iam_role_policy" "upload" {
  name = "s3-put-uploads"
  role = aws_iam_role.upload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "WriteUploads"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${var.bucket_arn}/${var.uploads_prefix}*"
      }
    ]
  })
}

# --- rol de crop ---
resource "aws_iam_role" "crop" {
  name               = "${local.crop_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_role_policy_attachment" "crop" {
  for_each   = toset(local.managed_policies)
  role       = aws_iam_role.crop.name
  policy_arn = each.value
}

# lee de uploads/, escribe en processed/ y consume la cola
resource "aws_iam_role_policy" "crop" {
  name = "s3-sqs-crop"
  role = aws_iam_role.crop.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadUploads"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${var.bucket_arn}/${var.uploads_prefix}*"
      },
      {
        Sid      = "WriteProcessed"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${var.bucket_arn}/${var.processed_prefix}*"
      },
      {
        Sid    = "ConsumeQueue"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility",
        ]
        Resource = var.queue_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Logs: se crean antes que las funciones para controlar la retencion
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${local.upload_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/${local.crop_name}"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------------
# Funciones: corren en las subredes privadas de las dos zonas (AZ-a y AZ-b)
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "upload" {
  function_name    = local.upload_name
  role             = aws_iam_role.upload.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = 256
  timeout          = local.upload_timeout
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256

  environment {
    variables = {
      S3_BUCKET     = var.bucket_name
      UPLOAD_PREFIX = var.uploads_prefix
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_upload_lambda_id]
  }

  depends_on = [
    aws_cloudwatch_log_group.upload,
    aws_iam_role_policy_attachment.upload,
  ]
}

resource "aws_lambda_function" "crop" {
  function_name    = local.crop_name
  role             = aws_iam_role.crop.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  architectures    = ["x86_64"]
  memory_size      = 512
  timeout          = local.crop_timeout
  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = var.bucket_name
      PROCESSED_PREFIX = var.processed_prefix
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.sg_crop_lambda_id]
  }

  depends_on = [
    aws_cloudwatch_log_group.crop,
    aws_iam_role_policy_attachment.crop,
  ]
}

# ---------------------------------------------------------------------------
# Trigger: el servicio Lambda lee la cola y le pasa los mensajes a crop
# ---------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "crop_sqs" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5
  function_response_types = ["ReportBatchItemFailures"]
  depends_on = [aws_iam_role_policy.crop]
}

