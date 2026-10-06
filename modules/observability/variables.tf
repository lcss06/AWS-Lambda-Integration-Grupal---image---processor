variable "name_prefix" {
  type = string
}

variable "dlq_name" {
  description = "DLQ que vigila la alarma"
  type        = string
}

variable "alarm_email" {
  description = "Correo que recibe la alarma"
  type        = string
}
