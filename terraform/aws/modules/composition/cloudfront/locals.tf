# ============================================================================
# Locals - Computed values and naming conventions
# ============================================================================

locals {
  # Common tags - include project, environment, and custom tags
  common_tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    },
    var.common_tags
  )

  # Create flag
  create = var.create && length(var.distributions) > 0

  # Distribution name prefix
  name_prefix = "${var.project_name}-cloudfront-${var.environment}"

  # Process origins based on type
  processed_origins = {
    for dist_name, dist_config in var.distributions :
    dist_name => [
      for origin in dist_config.origins :
      merge(origin, {
        # Determine domain name based on origin type
        resolved_domain_name = origin.type == "s3" && lookup(origin, "s3_bucket_domain_name", null) != null ? origin.s3_bucket_domain_name : origin.domain_name

        # Set origin access control ID for S3 origins
        origin_access_control_id = origin.type == "s3" && lookup(origin, "origin_access_control_id", null) == null ? try(aws_cloudfront_origin_access_control.this["${dist_name}-${origin.origin_id}"].id, null) : origin.origin_access_control_id

        # Set custom origin config for ALB/custom origins
        custom_origin_config = origin.type == "alb" || origin.type == "custom" ? lookup(origin, "custom_origin_config", {
          http_port              = 80
          https_port             = 443
          origin_protocol_policy = "https-only"
          origin_ssl_protocols   = ["TLSv1.2"]
        }) : null
      })
    ]
  }

  # Process cache behaviors with defaults
  processed_cache_behaviors = {
    for dist_name, dist_config in var.distributions :
    dist_name => {
      # Default cache behavior
      default = {
        target_origin_id       = dist_config.default_cache_behavior.target_origin_id
        allowed_methods        = dist_config.default_cache_behavior.allowed_methods
        cached_methods         = dist_config.default_cache_behavior.cached_methods
        viewer_protocol_policy = dist_config.default_cache_behavior.viewer_protocol_policy
        min_ttl               = dist_config.default_cache_behavior.ttl.min_ttl
        default_ttl           = dist_config.default_cache_behavior.ttl.default_ttl
        max_ttl               = dist_config.default_cache_behavior.ttl.max_ttl
        compress              = lookup(dist_config.default_cache_behavior, "compress", false)
        cache_policy_id       = lookup(dist_config.default_cache_behavior, "cache_policy_id", data.aws_cloudfront_cache_policy.caching_optimized[0].id)
        origin_request_policy_id = lookup(dist_config.default_cache_behavior, "origin_request_policy_id", data.aws_cloudfront_origin_request_policy.all_viewer[0].id)
        response_headers_policy_id = lookup(dist_config.default_cache_behavior, "response_headers_policy_id", data.aws_cloudfront_response_headers_policy.security_headers_policy[0].id)

        # Lambda function associations
        lambda_function_associations = {
          for idx, assoc in lookup(dist_config.default_cache_behavior, "lambda_function_associations", []) :
          "lambda_${idx}" => {
            event_type   = assoc.event_type
            lambda_arn   = assoc.lambda_arn
            include_body = lookup(assoc, "include_body", false)
          }
        }

        # CloudFront function associations
        function_associations = {
          for idx, assoc in lookup(dist_config.default_cache_behavior, "function_associations", []) :
          "function_${idx}" => {
            event_type   = assoc.event_type
            function_arn = assoc.function_arn
          }
        }
      }

      # Ordered cache behaviors
      ordered = [
        for behavior in lookup(dist_config, "ordered_cache_behaviors", []) :
        merge(behavior, {
          min_ttl               = lookup(behavior.ttl, "min_ttl", 0)
          default_ttl           = lookup(behavior.ttl, "default_ttl", 0)
          max_ttl               = lookup(behavior.ttl, "max_ttl", 0)
          compress              = lookup(behavior, "compress", false)
          cache_policy_id       = lookup(behavior, "cache_policy_id", data.aws_cloudfront_cache_policy.caching_optimized[0].id)
          origin_request_policy_id = lookup(behavior, "origin_request_policy_id", data.aws_cloudfront_origin_request_policy.all_viewer[0].id)
          response_headers_policy_id = lookup(behavior, "response_headers_policy_id", data.aws_cloudfront_response_headers_policy.security_headers_policy[0].id)

          # Lambda function associations
          lambda_function_associations = {
            for idx, assoc in lookup(behavior, "lambda_function_associations", []) :
            "lambda_${idx}" => {
              event_type   = assoc.event_type
              lambda_arn   = assoc.lambda_arn
              include_body = lookup(assoc, "include_body", false)
            }
          }

          # CloudFront function associations
          function_associations = {
            for idx, assoc in lookup(behavior, "function_associations", []) :
            "function_${idx}" => {
              event_type   = assoc.event_type
              function_arn = assoc.function_arn
            }
          }
        })
      ]
    }
  }

  # Logging bucket configuration
  log_bucket_config = var.enable_logging ? (
    var.log_bucket != null ? var.log_bucket : (
      var.create_log_bucket ? {
        bucket_name = "${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}"
        bucket_arn  = "arn:aws:s3:::${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}"
        bucket_domain_name = "${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}.s3.${data.aws_region.current[0].id}.amazonaws.com"
      } : null
    )
  ) : null

  # S3 buckets requiring OAC policies (metadata only, ARNs computed after creation)
  s3_bucket_origins = {
    for dist_name, dist_config in var.distributions :
    dist_name => [
      for origin in dist_config.origins : {
        bucket_id  = origin.s3_bucket_id
        bucket_arn = origin.s3_bucket_arn
        origin_id  = origin.origin_id
      } if origin.type == "s3" && lookup(origin, "apply_bucket_policy", true) && lookup(origin, "origin_access_control_id", null) != null
    ]
  }

  # CloudFront Functions map
  cloudfront_functions_map = {
    for fn in var.cloudfront_functions :
    fn.name => fn
  }

  # Response headers policies map
  response_headers_policies_map = {
    for policy in var.response_headers_policies :
    policy.name => policy
  }

  # Origin Access Controls map
  origin_access_controls_map = {
    for oac in var.origin_access_controls :
    oac.name => oac
  }
}