terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }
}

module "distribution" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.0"

  create = var.create

  aliases             = var.aliases
  comment             = var.comment
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  http_version        = var.http_version
  default_root_object = var.default_root_object
  web_acl_id          = var.web_acl_id
  staging             = var.staging
  continuous_deployment_policy_id = var.continuous_deployment_policy_id
  retain_on_delete    = var.retain_on_delete

  origin_access_control = var.origin_access_control

  origin       = var.origins
  origin_group = var.origin_groups

  default_cache_behavior  = var.default_cache_behavior
  ordered_cache_behavior  = var.ordered_cache_behaviors

  custom_error_response = var.custom_error_responses

  viewer_certificate = var.viewer_certificate

  restrictions = var.geo_restriction

  logging_config = var.logging_config

  tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}
