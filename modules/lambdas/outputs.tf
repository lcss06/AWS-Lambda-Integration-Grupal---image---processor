# CONTRATO: estos nombres los usa envs/*/main.tf. No los cambies sin avisar al grupo.
# Los valores son temporales para que "terraform validate" pase mientras se construye el módulo.

output "upload_function_name" {
  value = "" # TODO(Renato): aws_lambda_function.upload.function_name
}

output "upload_invoke_arn" {
  value = "" # TODO(Renato): aws_lambda_function.upload.invoke_arn
}

output "crop_function_name" {
  value = "" # TODO(Renato): aws_lambda_function.crop.function_name
}
