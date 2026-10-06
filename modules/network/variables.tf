variable "name_prefix" {
  type = string
}

variable "aws_region" {
  description = "Region para los nombres de servicio de los endpoints"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Subredes publicas (AZ-a, AZ-b)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Subredes privadas (AZ-a, AZ-b)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Crear un NAT Gateway por AZ"
  type        = bool
  default     = false
}

variable "bucket_arn" {
  description = "Bucket permitido en la politica del endpoint de S3"
  type        = string
}
