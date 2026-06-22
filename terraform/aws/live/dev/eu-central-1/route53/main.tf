provider "aws" {
  region = var.region
}

module "route53" {
  source = "../../../../modules/composition/route53"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  route53_zones = var.route53_zones

  tags = var.common_tags
}
