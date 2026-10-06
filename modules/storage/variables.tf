variable "name_prefix" {
  description = "Prefijo de nombres, ej: image-processor-dev."
  type        = string
}

variable "uploads_prefix" {
  type    = string
  default = "uploads/"
}

variable "processed_prefix" {
  type    = string
  default = "processed/"
}

variable "uploads_expiration_days" {
  type    = number
  default = 30
}

variable "processed_expiration_days" {
  type    = number
  default = 90
}

variable "crop_lambda_timeout" {
  description = "Timeout de la Lambda crop en segundos. La visibilidad de la cola es 6 veces este valor (360 s)."
  type        = number
  default     = 60
}

variable "max_receive_count" {
  description = "Intentos antes de mandar el mensaje a la DLQ."
  type        = number
  default     = 3
}
