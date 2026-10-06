variable "name_prefix" {
  description = "Prefijo de nombres, ej: image-processor-dev."
  type        = string
}

variable "log_retention_days" {
  description = "Retención del log group de acceso."
  type        = number
  default     = 14
}

variable "upload_function_name" {
  description = "Nombre de la Lambda upload (sale del módulo lambdas)."
  type        = string
}

variable "upload_invoke_arn" {
  description = "invoke_arn de la Lambda upload (sale del módulo lambdas)."
  type        = string
}

variable "throttling_rate_limit" {
  description = "Requests por segundo permitidos (diagrama: 10.000 rps)."
  type        = number
  default     = 10000
}

variable "throttling_burst_limit" {
  description = "Ráfaga máxima de requests."
  type        = number
  default     = 5000
}
