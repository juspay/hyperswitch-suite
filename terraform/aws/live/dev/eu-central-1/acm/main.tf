provider "aws" {
  region = var.region
}

module "acm" {
  source = "../../../../modules/composition/acm"

  environment  = var.environment
  project_name = var.project_name

  certificates = var.certificates

  tags = var.common_tags
}
