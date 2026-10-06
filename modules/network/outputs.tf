# CONTRATO: estos nombres los usa envs/*/main.tf. No los cambies sin avisar al grupo.
# Los valores son temporales para que "terraform validate" pase mientras se construye el módulo.

output "vpc_id" {
  value = "" # TODO(Jhonny): aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Subredes privadas AZ-a y AZ-b, para las Lambdas."
  value       = [] # TODO(Jhonny): aws_subnet.private[*].id
}

output "sg_upload_lambda_id" {
  value = "" # TODO(Jhonny): aws_security_group.upload_lambda.id
}

output "sg_crop_lambda_id" {
  value = "" # TODO(Jhonny): aws_security_group.crop_lambda.id
}
