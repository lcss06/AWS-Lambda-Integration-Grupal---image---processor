variable "project_name" {
  type    = string
  default = "image-processor"
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment tiene que ser dev, qa o prod."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "image-processor"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# las lambdas salen a S3 y SQS por los endpoints, el NAT solo lo dejamos en prod
variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "alarm_email" {
  description = "Correo para la alarma de la DLQ"
  type        = string
}
