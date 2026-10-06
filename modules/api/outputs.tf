output "api_id" {
  value = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "URL base de la API."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "upload_url" {
  description = "URL completa de POST /upload."
  value       = "${aws_apigatewayv2_api.this.api_endpoint}/upload"
}
