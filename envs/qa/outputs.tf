output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "environment" {
  value = var.environment
}

output "upload_url" {
  value = module.api.upload_url
}

output "bucket_name" {
  value = module.storage.bucket_name
}
