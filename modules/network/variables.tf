variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, qa, prod)"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Determina si se despliegan los NAT Gateways"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las 2 subredes públicas"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las 2 subredes privadas"
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket S3 para restringir el endpoint de S3"
}