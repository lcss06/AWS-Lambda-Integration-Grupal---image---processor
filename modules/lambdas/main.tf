# Parte 4 — Lambdas (Renato)
#
# Qué hay que construir (ver diagrama, bloques "Private Subnet" e "IAM"):
#  [ ] data "archive_file" para lambdas/upload y lambdas/crop (con node_modules ya instalados)
#  [ ] Log groups /aws/lambda/${var.name_prefix}-upload y -crop con var.log_retention_days
#      (crearlos ANTES de la función para que destroy también los borre)
#  [ ] Rol upload-lambda-role: AWSLambdaBasicExecutionRole + AWSLambdaVPCAccessExecutionRole
#      + s3:PutObject solo sobre "${var.bucket_arn}/${var.uploads_prefix}*"
#  [ ] Rol crop-lambda-role: las 2 administradas
#      + s3:GetObject sobre uploads/*, s3:PutObject sobre processed/*
#      + sqs:ReceiveMessage, DeleteMessage, GetQueueAttributes, ChangeMessageVisibility sobre var.queue_arn
#        (los usa el trigger aunque la función no llame a SQS)
#  [ ] Lambda upload: nodejs20.x, 256 MB, 30 s, index.handler,
#      env S3_BUCKET y UPLOAD_PREFIX, vpc_config con var.private_subnet_ids y var.sg_upload_lambda_id
#  [ ] Lambda crop: nodejs20.x, 512 MB, 60 s, index.handler,
#      env S3_BUCKET y PROCESSED_PREFIX, vpc_config con var.sg_crop_lambda_id
#  [ ] aws_lambda_event_source_mapping: cola -> crop, batch_size 5,
#      function_response_types = ["ReportBatchItemFailures"]
#
# El permiso para que API Gateway invoque la Lambda upload ya está en modules/api.
