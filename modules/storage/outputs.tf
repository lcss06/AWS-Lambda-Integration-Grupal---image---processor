# Los nombres se usan en envs/*/main.tf, no cambiarlos.

output "bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.images.arn
}

output "uploads_prefix" {
  value = var.uploads_prefix
}

output "processed_prefix" {
  value = var.processed_prefix
}

output "queue_arn" {
  value = aws_sqs_queue.main.arn
}

output "dlq_name" {
  value = aws_sqs_queue.dlq.name
}
