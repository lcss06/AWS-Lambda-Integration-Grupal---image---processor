variable "name_prefix" {
  description = "Prefijo de nombres, ej: image-processor-dev."
  type        = string
}

variable "lambdas_source_dir" {
  description = "Carpeta lambdas/ del repo (contiene upload/ y crop/)."
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "private_subnet_ids" {
  description = "Subredes privadas AZ-a y AZ-b. Una sola función con las 2 subredes = las 'réplicas' del diagrama."
  type        = list(string)
}

variable "sg_upload_lambda_id" {
  type = string
}

variable "sg_crop_lambda_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "uploads_prefix" {
  type = string
}

variable "processed_prefix" {
  type = string
}

variable "queue_arn" {
  description = "Cola principal, origen del trigger de la Lambda crop."
  type        = string
}
