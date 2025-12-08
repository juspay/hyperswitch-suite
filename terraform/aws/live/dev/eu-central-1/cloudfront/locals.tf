# ============================================================================
# Locals - Load and process configuration from YAML
# ============================================================================

locals {
  # Load configuration from YAML file
  config = yamldecode(file("${path.module}/config.yaml"))

  # Common tags
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )

  # Behavior templates for reuse
  behavior_templates = {
    # Static assets template
    static_assets = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
      ttl = {
        min_ttl    = 86400
        default_ttl = 31536000
        max_ttl    = 31536000
      }
    }

    # API template
    api = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD", "OPTIONS"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors_with_preflight.id
      ttl = {
        min_ttl    = 0
        default_ttl = 300
        max_ttl    = 3600
      }
    }

    # Admin template
    admin = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = false
      cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
      ttl = {
        min_ttl    = 0
        default_ttl = 0
        max_ttl    = 0
      }
    }

    # Media template
    media = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = false
      cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
      ttl = {
        min_ttl    = 86400
        default_ttl = 86400
        max_ttl    = 31536000
      }
    }

    # API v2 template (for newer APIs with different caching)
    api_v2 = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD", "OPTIONS"]
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
      cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
      response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors_with_preflight.id
      ttl = {
        min_ttl    = 0
        default_ttl = 180
        max_ttl    = 1800
      }
    }
  }

  # Process distributions from config.yaml
  processed_distributions = {
    for dist_name, dist_config in local.config.distributions :
    dist_name => {
      comment             = lookup(dist_config, "comment", null)
      enabled             = lookup(dist_config, "enabled", true)
      default_root_object = lookup(dist_config, "default_root_object", "index.html")
      price_class         = lookup(dist_config, "price_class", "PriceClass_All")
      
      # Domain aliases and viewer certificate
      aliases            = lookup(dist_config, "aliases", [])
      viewer_certificate = lookup(dist_config, "viewer_certificate", null)
      
      # Process origins
      origins = dist_config.origins

      # Process default cache behavior
      default_cache_behavior = dist_config.default_cache_behavior

      # Process ordered cache behaviors with template merging
      ordered_cache_behaviors = [
        for behavior in lookup(dist_config, "ordered_cache_behaviors", []) :
        lookup(behavior, "template", null) != null ? merge(
          # Use template as base
          local.behavior_templates[behavior.template],
          # Override with specific behavior settings (only non-null values)
          {
            path_pattern                = behavior.path_pattern
            target_origin_id            = behavior.target_origin_id
            allowed_methods             = lookup(behavior, "allowed_methods", local.behavior_templates[behavior.template].allowed_methods)
            cached_methods              = lookup(behavior, "cached_methods", local.behavior_templates[behavior.template].cached_methods)
            viewer_protocol_policy      = lookup(behavior, "viewer_protocol_policy", local.behavior_templates[behavior.template].viewer_protocol_policy)
            compress                    = lookup(behavior, "compress", local.behavior_templates[behavior.template].compress)
            cache_policy_id             = lookup(behavior, "cache_policy_id", local.behavior_templates[behavior.template].cache_policy_id)
            origin_request_policy_id    = lookup(behavior, "origin_request_policy_id", null)
            response_headers_policy_id  = lookup(behavior, "response_headers_policy_id", local.behavior_templates[behavior.template].response_headers_policy_id)
            ttl                         = lookup(behavior, "ttl", local.behavior_templates[behavior.template].ttl)
            lambda_function_associations = lookup(behavior, "lambda_function_associations", null) != null ? [
              for assoc in lookup(behavior, "lambda_function_associations", []) : assoc
            ] : []
            function_associations       = lookup(behavior, "function_associations", null) != null ? [
              for assoc in lookup(behavior, "function_associations", []) : assoc
            ] : []
          }
        ) : {
          # No template - use behavior settings directly
          path_pattern                = behavior.path_pattern
          target_origin_id            = behavior.target_origin_id
          allowed_methods             = lookup(behavior, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
          cached_methods              = lookup(behavior, "cached_methods", ["GET", "HEAD"])
          viewer_protocol_policy      = lookup(behavior, "viewer_protocol_policy", "redirect-to-https")
          compress                    = lookup(behavior, "compress", true)
          cache_policy_id             = lookup(behavior, "cache_policy_id", null)
          origin_request_policy_id    = lookup(behavior, "origin_request_policy_id", null)
          response_headers_policy_id  = lookup(behavior, "response_headers_policy_id", null)
          ttl                         = lookup(behavior, "ttl", null)
          lambda_function_associations = lookup(behavior, "lambda_function_associations", null) != null ? [
            for assoc in lookup(behavior, "lambda_function_associations", []) : assoc
          ] : []
          function_associations       = lookup(behavior, "function_associations", null) != null ? [
            for assoc in lookup(behavior, "function_associations", []) : assoc
          ] : []
        }
      ]

      # Custom error responses
      custom_error_responses = lookup(dist_config, "custom_error_responses", [])

      # Geo restrictions
      geo_restriction = lookup(dist_config, "geo_restriction", {})

      # Invalidation configuration
      invalidation = lookup(dist_config, "invalidation", null)
    }
  }

  # Process origins for each distribution
  processed_origins = {
    for dist_name, dist_config in local.processed_distributions :
    dist_name => dist_config.origins
  }

  # Merge behaviors with proper structure
  merged_behaviors = {
    for dist_name, dist_config in local.processed_distributions :
    dist_name => {
      ordered_cache_behaviors = dist_config.ordered_cache_behaviors
    }
  }

  # Transform CORS config from YAML (which has items as list) to module format (list of strings)
  transformed_response_headers_policies = [
    for policy in local.config.response_headers_policies :
    merge(
      policy,
      policy.cors_config != null ? {
        cors_config = merge(
          policy.cors_config,
          {
            access_control_allow_headers = try(policy.cors_config.access_control_allow_headers.items, policy.cors_config.access_control_allow_headers)
            access_control_allow_methods = try(policy.cors_config.access_control_allow_methods.items, policy.cors_config.access_control_allow_methods)
            access_control_allow_origins = try(policy.cors_config.access_control_allow_origins.items, policy.cors_config.access_control_allow_origins)
            access_control_expose_headers = try(policy.cors_config.access_control_expose_headers.items, lookup(policy.cors_config, "access_control_expose_headers", []))
          }
        )
      } : {}
    )
  ]

  # Transform cache policies from YAML to module format
  transformed_cache_policies = lookup(local.config, "cache_policies", [])

  # Transform origin request policies from YAML to module format
  transformed_origin_request_policies = lookup(local.config, "origin_request_policies", [])
}