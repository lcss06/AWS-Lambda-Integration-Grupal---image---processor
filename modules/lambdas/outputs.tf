# Los nombres se usan en envs/*/main.tf, no cambiarlos.

output "upload_function_name" {
  value = aws_lambda_function.upload.function_name
}

output "upload_invoke_arn" {
  value = aws_lambda_function.upload.invoke_arn
}

output "crop_function_name" {
  value = aws_lambda_function.crop.function_name
}