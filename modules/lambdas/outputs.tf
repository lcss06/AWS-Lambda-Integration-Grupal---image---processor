# Los nombres se usan en envs/*/main.tf, no cambiarlos.
# Valores vacios mientras se arma el modulo.

output "upload_function_name" {
  value = "" # TODO: aws_lambda_function.upload.function_name
}

output "upload_invoke_arn" {
  value = "" # TODO: aws_lambda_function.upload.invoke_arn
}

output "crop_function_name" {
  value = "" # TODO: aws_lambda_function.crop.function_name
}
