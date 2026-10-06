# mismo archivo en dev, qa y prod. Lo que cambia esta en terraform.tfvars

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_caller_identity" "current" {}

module "storage" {
  source = "../../modules/storage"

  name_prefix = local.name_prefix
}

module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  bucket_arn         = module.storage.bucket_arn
}

module "observability" {
  source = "../../modules/observability"

  name_prefix = local.name_prefix
  dlq_name    = module.storage.dlq_name
  alarm_email = var.alarm_email
}

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

module "api" {
  source = "../../modules/api"

  name_prefix          = local.name_prefix
  log_retention_days   = var.log_retention_days
  upload_function_name = module.lambdas.upload_function_name
  upload_invoke_arn    = module.lambdas.upload_invoke_arn
}
