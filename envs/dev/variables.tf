variable "project_name" {
  description = "Prefijo común de todos los recursos."
  type        = string
  default     = "image-processor"
}

variable "environment" {
  description = "Entorno a desplegar."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment debe ser dev, qa o prod."
  }
}

variable "aws_region" {
  description = "Región de AWS (el diagrama usa us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI con el que se despliega."
  type        = string
  default     = "image-processor"
}

variable "vpc_cidr" {
  description = "Rango de IPs de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Crea los 2 NAT Gateways. Las Lambdas no los necesitan (usan VPC Endpoints), así que solo se activan en PROD para respetar el diagrama."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Días que se guardan los logs de CloudWatch."
  type        = number
  default     = 14
}

variable "alarm_email" {
  description = "Correo que recibe la alarma de la DLQ (hay que confirmar la suscripción desde el correo)."
  type        = string
}
