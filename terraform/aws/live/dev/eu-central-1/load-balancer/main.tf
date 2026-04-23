provider "aws" {
  region = var.region
}

module "load_balancer" {
  source = "../../../../modules/composition/load-balancer"

  environment  = var.environment
  project_name = var.project_name

  create_alb = var.create_alb
  name       = var.name
  internal   = var.internal
  vpc_id     = var.vpc_id
  subnets    = var.subnets

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  enable_waf_fail_open             = var.enable_waf_fail_open
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  idle_timeout                     = var.idle_timeout

  access_logs = var.access_logs

  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules

  listeners               = var.listeners
  additional_certificates = var.additional_certificates

  route53_zone    = var.route53_zone
  route53_records = var.route53_records

  tags = var.common_tags
}
