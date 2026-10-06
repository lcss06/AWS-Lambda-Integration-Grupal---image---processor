variable "name_prefix" {
  description = "Prefijo de nombres, ej: image-processor-dev."
  type        = string
}

variable "aws_region" {
  description = "Región, para armar el nombre de servicio de los endpoints (com.amazonaws.<region>.s3)."
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Subredes públicas en AZ-a y AZ-b."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Subredes privadas en AZ-a y AZ-b (aquí viven las Lambdas)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "true = crea 1 NAT Gateway (+ Elastic IP) por AZ y la ruta 0.0.0.0/0 de las privadas."
  type        = bool
  default     = false
}

variable "bucket_arn" {
  description = "ARN del bucket de imágenes, para limitar la política del endpoint de S3."
  type        = string
}
