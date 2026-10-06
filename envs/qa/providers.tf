# Autenticación por perfil (~/.aws/credentials o SSO), como pide la consigna.
# Nunca se escriben access keys en el código.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
