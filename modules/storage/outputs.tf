# Los nombres se usan en envs/*/main.tf, no cambiarlos.
# Valores vacios mientras se arma el modulo.

output "bucket_name" {
  value = "" # TODO: aws_s3_bucket.images.bucket
}

output "bucket_arn" {
  value = "" # TODO: aws_s3_bucket.images.arn
}

output "uploads_prefix" {
  value = var.uploads_prefix
}

output "processed_prefix" {
  value = var.processed_prefix
}

output "queue_arn" {
  value = "" # TODO: aws_sqs_queue.main.arn
}

output "dlq_name" {
  value = "" # TODO: aws_sqs_queue.dlq.name
}
