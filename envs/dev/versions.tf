terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # random: sufijo único del bucket (módulo storage)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    # archive: empaquetar el código de las Lambdas en .zip (módulo lambdas)
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}
