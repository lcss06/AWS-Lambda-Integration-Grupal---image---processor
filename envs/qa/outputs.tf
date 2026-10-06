output "account_id" {
  description = "Cuenta de AWS donde se desplegó (evidencia para el PDF)."
  value       = data.aws_caller_identity.current.account_id
}

output "environment" {
  value = var.environment
}

output "upload_url" {
  description = "URL para subir imágenes: curl -F \"file=@foto.jpg\" <upload_url>"
  value       = module.api.upload_url
}

output "bucket_name" {
  description = "Bucket donde quedan uploads/ y processed/."
  value       = module.storage.bucket_name
}
