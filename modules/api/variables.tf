variable "name_prefix" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "upload_function_name" {
  type = string
}

variable "upload_invoke_arn" {
  type = string
}

variable "throttling_rate_limit" {
  type    = number
  default = 10000
}

variable "throttling_burst_limit" {
  type    = number
  default = 5000
}
