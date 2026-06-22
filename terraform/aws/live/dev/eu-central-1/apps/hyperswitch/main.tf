provider "aws" {
  region = var.region
}

module "hyperswitch" {
  source = "../../../../../modules/application-resources/hyperswitch"

  environment  = var.environment
  project_name = var.project_name
  region       = var.region

  cluster_service_accounts = var.cluster_service_accounts

  kms                = var.kms
  s3_dashboard_themes = var.s3_dashboard_themes
  s3_file_uploads    = var.s3_file_uploads
  ses                = var.ses
  secrets_manager    = var.secrets_manager
  lambda             = var.lambda
  assume_role        = var.assume_role

  tags = var.common_tags
}
