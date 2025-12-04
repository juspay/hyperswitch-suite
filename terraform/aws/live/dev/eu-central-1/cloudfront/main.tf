# ============================================================================
# CloudFront CDN - Live Layer (Dev Environment)
# ============================================================================

provider "aws" {
  region = var.region
}

# CloudFront Module
module "cloudfront" {
  source = "../../../../modules/composition/cloudfront"

  environment  = var.environment
  project_name = var.project_name
  common_tags  = local.common_tags

  # Distributions configuration from config.yaml
  distributions = {
    for name, dist in local.processed_distributions :
    name => {
      # Origins - from YAML
      origins = local.processed_origins[name]

      # Default cache behavior
      default_cache_behavior = dist.default_cache_behavior

      # Ordered cache behaviors - using merged behaviors from locals
      ordered_cache_behaviors = local.merged_behaviors[name].ordered_cache_behaviors

      # Custom error responses
      custom_error_responses = dist.custom_error_responses

      # Additional configuration
      default_root_object = dist.default_root_object
      price_class        = dist.price_class
      enabled            = dist.enabled
      comment            = dist.comment

      # Geo restrictions
      geo_restriction = dist.geo_restriction

      # Invalidation
      invalidation = dist.invalidation
    }
  }

  # Logging configuration
  enable_logging    = var.enable_logging
  create_log_bucket = var.create_log_bucket
  log_bucket        = local.log_bucket_config

  # Origin Access Controls from config.yaml
  origin_access_controls = lookup(local.config, "origin_access_controls", [])

  # CloudFront Functions from config.yaml
  cloudfront_functions = local.config.cloudfront_functions

  # Response Headers Policies from config.yaml (transformed)
  response_headers_policies = local.transformed_response_headers_policies
}