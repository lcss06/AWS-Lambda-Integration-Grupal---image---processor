# Parte 2 — Red (Jhonny)
#
# Qué hay que construir (ver diagrama, bloque "VPC"):
#  [ ] aws_vpc con enable_dns_support y enable_dns_hostnames = true
#  [ ] data "aws_availability_zones" para tomar AZ-a y AZ-b
#  [ ] 2 subredes públicas (var.public_subnet_cidrs) y 2 privadas (var.private_subnet_cidrs)
#  [ ] Internet Gateway + tabla de rutas pública con 0.0.0.0/0 -> IGW
#  [ ] Si var.enable_nat_gateway: 2 Elastic IP + 2 NAT Gateway (uno por subred pública)
#      Tip: count = var.enable_nat_gateway ? 2 : 0
#  [ ] 2 tablas de rutas privadas (una por AZ). Ruta 0.0.0.0/0 -> NAT de su AZ solo si hay NAT
#  [ ] VPC Endpoint S3 tipo Gateway asociado a las tablas privadas.
#      Política: s3:GetObject y s3:PutObject solo sobre "${var.bucket_arn}/*"
#  [ ] VPC Endpoint SQS tipo Interface en las 2 subredes privadas, private_dns_enabled = true,
#      con su propio SG (sg-vpce-sqs): entrada TCP 443 desde sg-upload-lambda y sg-crop-lambda
#  [ ] sg-upload-lambda y sg-crop-lambda: sin reglas de entrada. Salida TCP 443 hacia:
#        - el endpoint de S3 -> OJO: es Gateway, no tiene SG. Se usa
#          prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
#        - el endpoint de SQS -> security_groups = [sg-vpce-sqs]
#
# Cuando termines, reemplaza los valores de outputs.tf por los recursos reales.
