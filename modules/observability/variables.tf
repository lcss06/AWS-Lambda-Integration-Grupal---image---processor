variable "name_prefix" {
  description = "Prefijo de nombres, ej: image-processor-dev."
  type        = string
}

variable "dlq_name" {
  description = "Nombre de la DLQ que vigila la alarma."
  type        = string
}

variable "alarm_email" {
  description = "Correo suscrito al tópico SNS."
  type        = string
}
