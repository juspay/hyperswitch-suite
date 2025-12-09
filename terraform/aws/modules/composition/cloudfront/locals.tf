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

  # Origin Access Controls map (needs to be defined before processed_origins)
  origin_access_controls_map = {
    for idx, oac in var.origin_access_controls :
    oac.name => aws_cloudfront_origin_access_control.this[idx].id
  }

  # CloudFront Functions ARN map for resolving function names to ARNs
  cloudfront_function_arns_map = module.cloudfront_resources.cloudfront_function_arns

  # Response Headers Policies ID map for resolving policy names to IDs
  response_headers_policy_ids_map = module.cloudfront_resources.response_headers_policy_ids

  # Maps for dynamically fetched AWS managed policies
  # These maps allow lookup by policy name and return the policy ID
  aws_managed_cache_policy_ids = merge([
    for idx, policy in data.aws_cloudfront_cache_policy.aws_managed :
    {
      # Map both "AllViewer" and "Managed-AllViewer" to the policy ID
      for name in [policy.name, substr(policy.name, 8, -1)] :
      name => policy.id
      if startswith(policy.name, "Managed-")
    }
  ]...)

  aws_managed_origin_request_policy_ids = merge([
    for idx, policy in data.aws_cloudfront_origin_request_policy.aws_managed :
    {
      # Map both "AllViewer" and "Managed-AllViewer" to the policy ID
      for name in [policy.name, substr(policy.name, 8, -1)] :
      name => policy.id
      if startswith(policy.name, "Managed-")
    }
  ]...)

  aws_managed_response_headers_policy_ids = merge([
    for idx, policy in data.aws_cloudfront_response_headers_policy.aws_managed :
    {
      # Map both "SecurityHeadersPolicy" and "Managed-SecurityHeadersPolicy" to the policy ID
      for name in [policy.name, substr(policy.name, 8, -1)] :
      name => policy.id
      if startswith(policy.name, "Managed-")
    }
  ]...)

  # Process origins based on type
  processed_origins = {
    for dist_name, dist_config in var.distributions :
    dist_name => [
      for origin in dist_config.origins :
      merge(origin, {
        # Determine domain name based on origin type
        resolved_domain_name = origin.type == "s3" && lookup(origin, "s3_bucket_domain_name", null) != null ? origin.s3_bucket_domain_name : origin.domain_name

        # Set origin access control ID for S3 origins
        # If origin_access_control_id is provided as a name, look it up in the OAC map
        # Otherwise try to auto-generate using pattern, or use the provided ID directly
        origin_access_control_id = origin.type == "s3" ? (
          lookup(origin, "origin_access_control_id", null) != null ? (
            # Check if it's a name reference (exists in our map)
            contains(keys(local.origin_access_controls_map), origin.origin_access_control_id) ?
              local.origin_access_controls_map[origin.origin_access_control_id] :
              origin.origin_access_control_id
          ) : try(aws_cloudfront_origin_access_control.this["${dist_name}-${origin.origin_id}"].id, null)
        ) : null

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
        # When cache_policy_id is set, TTL must be 0 (controlled by the policy)
        min_ttl               = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.min_ttl
        default_ttl           = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.default_ttl
        max_ttl               = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.max_ttl
        compress              = lookup(dist_config.default_cache_behavior, "compress", false)
        cache_policy_id       = lookup(dist_config.default_cache_behavior, "cache_policy_id", null)
        origin_request_policy_id = lookup(dist_config.default_cache_behavior, "origin_request_policy_id", null)
        response_headers_policy_id = lookup(dist_config.default_cache_behavior, "response_headers_policy_id", null)

        # Resolved policy IDs - dynamically resolve custom, AWS managed, ARN, and UUID references
        resolved_cache_policy_id = (
          lookup(dist_config.default_cache_behavior, "cache_policy_id", null) == null ? null :
          contains(keys(module.cloudfront_resources.cache_policy_ids), dist_config.default_cache_behavior.cache_policy_id) ?
            module.cloudfront_resources.cache_policy_ids[dist_config.default_cache_behavior.cache_policy_id] :
          startswith(dist_config.default_cache_behavior.cache_policy_id, "arn:") ?
            dist_config.default_cache_behavior.cache_policy_id :
          can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", dist_config.default_cache_behavior.cache_policy_id)) ?
            dist_config.default_cache_behavior.cache_policy_id :
          contains(keys(local.aws_managed_cache_policy_ids), dist_config.default_cache_behavior.cache_policy_id) ?
            local.aws_managed_cache_policy_ids[dist_config.default_cache_behavior.cache_policy_id] :
          dist_config.default_cache_behavior.cache_policy_id
        )

        resolved_origin_request_policy_id = (
          lookup(dist_config.default_cache_behavior, "origin_request_policy_id", null) == null ? null :
          contains(keys(module.cloudfront_resources.origin_request_policy_ids), dist_config.default_cache_behavior.origin_request_policy_id) ?
            module.cloudfront_resources.origin_request_policy_ids[dist_config.default_cache_behavior.origin_request_policy_id] :
          startswith(dist_config.default_cache_behavior.origin_request_policy_id, "arn:") ?
            dist_config.default_cache_behavior.origin_request_policy_id :
          can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", dist_config.default_cache_behavior.origin_request_policy_id)) ?
            dist_config.default_cache_behavior.origin_request_policy_id :
          contains(keys(local.aws_managed_origin_request_policy_ids), dist_config.default_cache_behavior.origin_request_policy_id) ?
            local.aws_managed_origin_request_policy_ids[dist_config.default_cache_behavior.origin_request_policy_id] :
          dist_config.default_cache_behavior.origin_request_policy_id
        )

        resolved_response_headers_policy_id = (
          lookup(dist_config.default_cache_behavior, "response_headers_policy_id", null) == null ? null :
          contains(keys(module.cloudfront_resources.response_headers_policy_ids), dist_config.default_cache_behavior.response_headers_policy_id) ?
            module.cloudfront_resources.response_headers_policy_ids[dist_config.default_cache_behavior.response_headers_policy_id] :
          startswith(dist_config.default_cache_behavior.response_headers_policy_id, "arn:") ?
            dist_config.default_cache_behavior.response_headers_policy_id :
          can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", dist_config.default_cache_behavior.response_headers_policy_id)) ?
            dist_config.default_cache_behavior.response_headers_policy_id :
          contains(keys(local.aws_managed_response_headers_policy_ids), dist_config.default_cache_behavior.response_headers_policy_id) ?
            local.aws_managed_response_headers_policy_ids[dist_config.default_cache_behavior.response_headers_policy_id] :
          dist_config.default_cache_behavior.response_headers_policy_id
        )

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
            event_type = assoc.event_type
            # Resolve function name to ARN if it's a name reference
            function_arn = (
              contains(keys(local.cloudfront_function_arns_map), assoc.function_arn) ?
              local.cloudfront_function_arns_map[assoc.function_arn] :
              assoc.function_arn
            )
          }
        }
      }

      # Ordered cache behaviors
      ordered = [
        for behavior in lookup(dist_config, "ordered_cache_behaviors", []) :
        merge(behavior, {
          # When cache_policy_id is set, TTL must be 0 (controlled by the policy)
          min_ttl               = lookup(behavior, "cache_policy_id", null) != null ? 0 : lookup(behavior.ttl, "min_ttl", 0)
          default_ttl           = lookup(behavior, "cache_policy_id", null) != null ? 0 : lookup(behavior.ttl, "default_ttl", 0)
          max_ttl               = lookup(behavior, "cache_policy_id", null) != null ? 0 : lookup(behavior.ttl, "max_ttl", 0)
          compress              = lookup(behavior, "compress", false)
          cache_policy_id       = lookup(behavior, "cache_policy_id", null)
          origin_request_policy_id = lookup(behavior, "origin_request_policy_id", null)
          response_headers_policy_id = lookup(behavior, "response_headers_policy_id", null)

          # Resolved policy IDs - dynamically resolve custom, AWS managed, ARN, and UUID references
          resolved_cache_policy_id = (
            lookup(behavior, "cache_policy_id", null) == null ? null :
            contains(keys(module.cloudfront_resources.cache_policy_ids), behavior.cache_policy_id) ?
              module.cloudfront_resources.cache_policy_ids[behavior.cache_policy_id] :
            startswith(behavior.cache_policy_id, "arn:") ?
              behavior.cache_policy_id :
            can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", behavior.cache_policy_id)) ?
              behavior.cache_policy_id :
            contains(keys(local.aws_managed_cache_policy_ids), behavior.cache_policy_id) ?
              local.aws_managed_cache_policy_ids[behavior.cache_policy_id] :
            behavior.cache_policy_id
          )

          resolved_origin_request_policy_id = (
            lookup(behavior, "origin_request_policy_id", null) == null ? null :
            contains(keys(module.cloudfront_resources.origin_request_policy_ids), behavior.origin_request_policy_id) ?
              module.cloudfront_resources.origin_request_policy_ids[behavior.origin_request_policy_id] :
            startswith(behavior.origin_request_policy_id, "arn:") ?
              behavior.origin_request_policy_id :
            can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", behavior.origin_request_policy_id)) ?
              behavior.origin_request_policy_id :
            contains(keys(local.aws_managed_origin_request_policy_ids), behavior.origin_request_policy_id) ?
              local.aws_managed_origin_request_policy_ids[behavior.origin_request_policy_id] :
            behavior.origin_request_policy_id
          )

          resolved_response_headers_policy_id = (
            lookup(behavior, "response_headers_policy_id", null) == null ? null :
            contains(keys(module.cloudfront_resources.response_headers_policy_ids), behavior.response_headers_policy_id) ?
              module.cloudfront_resources.response_headers_policy_ids[behavior.response_headers_policy_id] :
            startswith(behavior.response_headers_policy_id, "arn:") ?
              behavior.response_headers_policy_id :
            can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", behavior.response_headers_policy_id)) ?
              behavior.response_headers_policy_id :
            contains(keys(local.aws_managed_response_headers_policy_ids), behavior.response_headers_policy_id) ?
              local.aws_managed_response_headers_policy_ids[behavior.response_headers_policy_id] :
            behavior.response_headers_policy_id
          )

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
              event_type = assoc.event_type
              # Resolve function name to ARN if it's a name reference
              function_arn = (
                contains(keys(local.cloudfront_function_arns_map), assoc.function_arn) ?
                local.cloudfront_function_arns_map[assoc.function_arn] :
                assoc.function_arn
              )
            }
          }
        })
      ]
    }
  }

  # Logging bucket configuration
  # Priority: 1. Existing bucket ARN, 2. Create new bucket, 3. Null (logging disabled)
  log_bucket_config = var.enable_logging ? (
    var.log_bucket_arn != null ? {
      # Extract bucket name from ARN
      bucket_name        = replace(var.log_bucket_arn, "arn:aws:s3:::", "")
      bucket_arn         = var.log_bucket_arn
      bucket_domain_name = "${replace(var.log_bucket_arn, "arn:aws:s3:::", "")}.s3.amazonaws.com"
      prefix             = var.log_prefix
    } : (
      var.create_log_bucket ? {
        bucket_name        = "${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}"
        bucket_arn         = "arn:aws:s3:::${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}"
        bucket_domain_name = "${local.name_prefix}-logs-${data.aws_caller_identity.current[0].account_id}-${data.aws_region.current[0].id}.s3.${data.aws_region.current[0].id}.amazonaws.com"
        prefix             = var.log_prefix
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
}

