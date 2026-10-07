# Los nombres se usan en envs/*/main.tf, no cambiarlos.
# Valores vacios mientras se arma el modulo.

output "vpc_id" {
  value = "" # TODO: aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Subredes privadas AZ-a y AZ-b, para las Lambdas."
  value       = [] # TODO: aws_subnet.private[*].id
}

output "sg_upload_lambda_id" {
  value = "" # TODO: aws_security_group.upload_lambda.id
}

output "sg_crop_lambda_id" {
  value = "" # TODO: aws_security_group.crop_lambda.id
}
