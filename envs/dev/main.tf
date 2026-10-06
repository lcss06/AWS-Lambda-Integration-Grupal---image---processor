# Este archivo es IGUAL en envs/dev, envs/qa y envs/prod.
# Lo único que cambia entre entornos es terraform.tfvars.
# Si lo modificas, copia el cambio a los tres.

locals {
  name_prefix = "${var.project_name}-${var.environment}" # ej: image-processor-dev
}

data "aws_caller_identity" "current" {}

# Parte 3 (Karina): bucket S3, cola SQS, DLQ y notificación S3 -> SQS
module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
}

# Parte 2 (Jhonny): VPC, subredes, NAT, endpoints y security groups
module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  bucket_arn         = module.storage.bucket_arn # para la política del endpoint de S3
}

# Parte 3 (Karina): tópico SNS y alarma sobre la DLQ
module "observability" {
  source = "../../modules/observability"

  name_prefix = local.name_prefix
  dlq_name    = module.storage.dlq_name
  alarm_email = var.alarm_email
}

# Parte 4 (Renato): roles IAM, Lambdas upload y crop, log groups y trigger SQS
module "lambdas" {
  source = "../../modules/lambdas"

  name_prefix        = local.name_prefix
  lambdas_source_dir = "${path.root}/../../lambdas"
  log_retention_days = var.log_retention_days

  private_subnet_ids  = module.network.private_subnet_ids
  sg_upload_lambda_id = module.network.sg_upload_lambda_id
  sg_crop_lambda_id   = module.network.sg_crop_lambda_id

  bucket_name      = module.storage.bucket_name
  bucket_arn       = module.storage.bucket_arn
  uploads_prefix   = module.storage.uploads_prefix
  processed_prefix = module.storage.processed_prefix
  queue_arn        = module.storage.queue_arn
}

# Parte 1 (Lucas): API Gateway HTTP API con la ruta POST /upload
module "api" {
  source = "../../modules/api"

  name_prefix          = local.name_prefix
  log_retention_days   = var.log_retention_days
  upload_function_name = module.lambdas.upload_function_name
  upload_invoke_arn    = module.lambdas.upload_invoke_arn
}
