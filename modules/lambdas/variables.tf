variable "name_prefix" {
  type = string
}

variable "lambdas_source_dir" {
  description = "Ruta a la carpeta lambdas/ del repo"
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "private_subnet_ids" {
  description = "Subredes privadas donde corren las lambdas"
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
  description = "Cola que dispara la lambda crop"
  type        = string
}
