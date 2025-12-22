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
      web_acl_id         = dist.web_acl_id

      # Domain aliases and viewer certificate
      aliases            = dist.aliases
      viewer_certificate = dist.viewer_certificate

      # Geo restrictions
      geo_restriction = dist.geo_restriction

      # Invalidation
      invalidation = dist.invalidation
    }
  }

  # Logging configuration
  enable_logging    = var.enable_logging
  create_log_bucket = var.create_log_bucket
  log_bucket_arn    = var.log_bucket_arn
  log_prefix        = var.log_prefix

  # Origin Access Controls from config.yaml
  origin_access_controls = local.origin_access_controls

  # CloudFront Functions from config.yaml
  cloudfront_functions = local.cloudfront_functions

  # Response Headers Policies from config.yaml (transformed)
  response_headers_policies = local.transformed_response_headers_policies

  # Cache Policies from config.yaml (transformed)
  cache_policies = local.transformed_cache_policies

  # Origin Request Policies from config.yaml (transformed)
  origin_request_policies = local.transformed_origin_request_policies
}