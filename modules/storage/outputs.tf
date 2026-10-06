# CONTRATO: estos nombres los usa envs/*/main.tf. No los cambies sin avisar al grupo.
# Los valores son temporales para que "terraform validate" pase mientras se construye el módulo.

output "bucket_name" {
  value = "" # TODO(Karina): aws_s3_bucket.images.bucket
}

output "bucket_arn" {
  value = "" # TODO(Karina): aws_s3_bucket.images.arn
}

output "uploads_prefix" {
  value = var.uploads_prefix
}

output "processed_prefix" {
  value = var.processed_prefix
}

output "queue_arn" {
  value = "" # TODO(Karina): aws_sqs_queue.main.arn
}

output "dlq_name" {
  value = "" # TODO(Karina): aws_sqs_queue.dlq.name
}
