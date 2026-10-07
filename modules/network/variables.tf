variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, qa, prod)"
}

variable "name_prefix" {
  type        = string
  description = "Prefijo para los nombres de los recursos"
}

variable "aws_region" {
  type        = string
  description = "Region para los nombres de servicio de los endpoints"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las 2 subredes públicas"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Lista de bloques CIDR para las 2 subredes privadas"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Determina si se despliegan los NAT Gateways"
}

variable "bucket_arn" {
  type        = string
  description = "ARN del bucket S3 para restringir el endpoint de S3"
}
