# Parte 3 — Almacenamiento (Karina)
#
# Qué hay que construir (ver diagrama, bloques "Amazon S3" y "Amazon SQS"):
#  [ ] random_id para el sufijo: bucket "${var.name_prefix}-images-<sufijo>"
#  [ ] aws_s3_bucket con force_destroy = true (si no, terraform destroy falla por el versionado)
#  [ ] aws_s3_bucket_public_access_block: los 4 en true (totalmente privado)
#  [ ] aws_s3_bucket_server_side_encryption_configuration: AES256
#  [ ] aws_s3_bucket_versioning: Enabled
#  [ ] aws_s3_bucket_lifecycle_configuration:
#        - uploads/ expira a los 30 días, processed/ a los 90
#        - con versionado, agregar noncurrent_version_expiration para no acumular versiones viejas
#  [ ] Cola DLQ "${var.name_prefix}-image-dlq": retención 14 días (1209600 s)
#  [ ] Cola principal "${var.name_prefix}-image-queue": Standard, visibilidad 360 s,
#      retención 1 día (86400 s), long polling 20 s, redrive_policy con maxReceiveCount = 3
#  [ ] aws_sqs_queue_policy: permitir sqs:SendMessage a s3.amazonaws.com
#      con condición aws:SourceArn = ARN del bucket (sin esto el paso siguiente falla)
#  [ ] aws_s3_bucket_notification -> cola, evento s3:ObjectCreated:*,
#      filter_prefix = var.uploads_prefix  (OJO: sin el filtro, processed/ dispara un bucle)
#      depends_on = [aws_sqs_queue_policy...]
#
# Cuando termines, reemplaza los valores de outputs.tf por los recursos reales.
