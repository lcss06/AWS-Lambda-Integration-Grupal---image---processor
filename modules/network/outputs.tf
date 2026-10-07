output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = aws_subnet.private[*].id
}

output "sg_upload_lambda_id" {
  description = "ID del Security Group para la Lambda de Upload"
  value       = aws_security_group.upload_lambda.id
}

output "sg_crop_lambda_id" {
  description = "ID del Security Group para la Lambda de Crop"
  value       = aws_security_group.crop_lambda.id
}