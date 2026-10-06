# API Gateway HTTP API (v2) — paso 1 y 2 del diagrama.
# Cliente -> HTTPS POST /upload -> Lambda Proxy (payload 2.0) -> upload-lambda
#
# Notas:
# - El endpoint por defecto de un HTTP API solo acepta HTTPS con TLS 1.2+,
#   no hay que configurar nada para cumplir eso.
# - El HTTP API acepta hasta 10 MB de payload, pero la Lambda solo recibe 6 MB
#   (y el binario llega en base64, +33%), por eso la Lambda limita a ~4 MB.
# - Los HTTP API no necesitan el rol de cuenta para CloudWatch (eso es de REST API).

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "Recibe imágenes y las envía a la Lambda upload"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "upload" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = var.upload_invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000 # igual al timeout de la Lambda upload (30 s), el máximo de HTTP API
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/${var.name_prefix}-api"
  retention_in_days = var.log_retention_days
}

# Stage "$default" con auto-deploy: cada cambio de rutas se publica solo
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      integrationError   = "$context.integrationErrorMessage"
    })
  }
}

# Sin este permiso API Gateway no puede invocar la Lambda (respondería 500).
# source_arn lo limita a esta API y a la ruta /upload.
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.upload_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*/upload"
}
