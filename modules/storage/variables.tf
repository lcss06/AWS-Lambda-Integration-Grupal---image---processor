variable "name_prefix" {
  type = string
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
  description = "Timeout de la lambda crop, la visibilidad de la cola es 6 veces esto"
  type        = number
  default     = 60
}

variable "max_receive_count" {
  description = "Intentos antes de mandar a la DLQ"
  type        = number
  default     = 3
}

variable "noncurrent_expiration_days" {
  description = "Dias que se guardan las versiones viejas antes de borrarlas"
  type        = number
  default     = 7
}
