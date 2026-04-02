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

  # Distributions config
  all_distributions = var.distributions

  # VPC Origins map - collect all vpc_origin type origins across distributions
  vpc_origins_map = {
    for origin in flatten([
      for dist_name, dist_config in var.distributions : [
        for origin in dist_config.origins :
        {
          key = "${dist_name}-${origin.origin_id}"
          value = {
            name                   = lookup(origin.vpc_origin_config, "name", "${var.project_name}-${dist_name}-${origin.origin_id}-${var.environment}")
            alb_arn                = origin.vpc_origin_config.alb_arn
            http_port              = lookup(origin.vpc_origin_config, "http_port", 80)
            https_port             = lookup(origin.vpc_origin_config, "https_port", 443)
            origin_protocol_policy = lookup(origin.vpc_origin_config, "origin_protocol_policy", "https-only")
            origin_ssl_protocols = lookup(origin.vpc_origin_config, "origin_ssl_protocols", { items = ["TLSv1.2"], quantity = 1 })
            origin_id              = origin.origin_id
            dist_name              = dist_name
          }
        }
        if origin.type == "vpc_origin" && lookup(origin, "vpc_origin_config", null) != null
      ]
    ]) : origin.key => origin.value
  }

  # VPC Origin IDs map for resolving origin_id to vpc_origin_id
  vpc_origin_ids_map = {
    for key, vpc_origin in aws_cloudfront_vpc_origin.this :
    key => vpc_origin.id
  }

  # CloudFront Functions ARN map for resolving function names to ARNs
  cloudfront_function_arns_map = { for k, v in aws_cloudfront_function.this : k => v.arn }

  # Response Headers Policies ID map for resolving policy names to IDs
  response_headers_policy_ids_map = { for k, v in aws_cloudfront_response_headers_policy.this : k => v.id }

  # Cache Policies ID map for resolving policy names to IDs
  cache_policy_ids_map = { for k, v in aws_cloudfront_cache_policy.this : k => v.id }

  # Origin Request Policies ID map for resolving policy names to IDs
  origin_request_policy_ids_map = { for k, v in aws_cloudfront_origin_request_policy.this : k => v.id }

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

  # Process origins - generic, supports any origin type
  processed_origins = {
    for dist_name, dist_config in local.all_distributions :
    dist_name => [
      for origin in dist_config.origins :
      merge(origin, {
        # Determine domain name based on origin type
        resolved_domain_name = lookup(origin, "s3_bucket_domain_name", lookup(origin, "domain_name", null))

        # Use origin_access_identity from origin config if provided (for S3 origins)
        origin_access_identity = lookup(origin, "origin_access_identity", null)

        # Merge custom origin config with defaults for non-S3 origins
        custom_origin_config = lookup(origin, "type", "") != "s3" ? merge(
          {
            http_port                = 80
            https_port               = 443
            origin_protocol_policy   = "https-only"
            origin_ssl_protocols     = ["TLSv1.2"]
            origin_keepalive_timeout = 5
            origin_read_timeout      = 30
          },
          lookup(origin, "custom_origin_config", {})
        ) : null

        # Set VPC Origin ID for vpc_origin type origins
        vpc_origin_id = origin.type == "vpc_origin" ? (
          lookup(local.vpc_origin_ids_map, "${dist_name}-${origin.origin_id}", null)
        ) : null
      })
    ]
  }

  # Process cache behaviors with defaults
  processed_cache_behaviors = {
    for dist_name, dist_config in local.all_distributions :
    dist_name => {
      # Default cache behavior
      default = {
        target_origin_id       = dist_config.default_cache_behavior.target_origin_id
        allowed_methods        = dist_config.default_cache_behavior.allowed_methods
        cached_methods         = dist_config.default_cache_behavior.cached_methods
        viewer_protocol_policy = dist_config.default_cache_behavior.viewer_protocol_policy
        # When cache_policy_id is set, TTL must be 0 (controlled by the policy)
        min_ttl                    = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.min_ttl
        default_ttl                = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.default_ttl
        max_ttl                    = lookup(dist_config.default_cache_behavior, "cache_policy_id", null) != null ? 0 : dist_config.default_cache_behavior.ttl.max_ttl
        compress                   = lookup(dist_config.default_cache_behavior, "compress", false)
        cache_policy_id            = lookup(dist_config.default_cache_behavior, "cache_policy_id", null)
        origin_request_policy_id   = lookup(dist_config.default_cache_behavior, "origin_request_policy_id", null)
        response_headers_policy_id = lookup(dist_config.default_cache_behavior, "response_headers_policy_id", null)

        use_forwarded_values     = lookup(dist_config.default_cache_behavior, "use_forwarded_values", false)
        query_string             = lookup(dist_config.default_cache_behavior, "query_string", false)
        headers                  = lookup(dist_config.default_cache_behavior, "headers", [])
        cookies_forward          = lookup(dist_config.default_cache_behavior, "cookies_forward", "none")

        # Resolved policy IDs - dynamically resolve custom, AWS managed, ARN, and UUID references
        resolved_cache_policy_id = (
          lookup(dist_config.default_cache_behavior, "cache_policy_id", null) == null ? null :
          contains(keys(local.cache_policy_ids_map), dist_config.default_cache_behavior.cache_policy_id) ?
          local.cache_policy_ids_map[dist_config.default_cache_behavior.cache_policy_id] :
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
          contains(keys(local.origin_request_policy_ids_map), dist_config.default_cache_behavior.origin_request_policy_id) ?
          local.origin_request_policy_ids_map[dist_config.default_cache_behavior.origin_request_policy_id] :
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
          contains(keys(local.response_headers_policy_ids_map), dist_config.default_cache_behavior.response_headers_policy_id) ?
          local.response_headers_policy_ids_map[dist_config.default_cache_behavior.response_headers_policy_id] :
          startswith(dist_config.default_cache_behavior.response_headers_policy_id, "arn:") ?
          dist_config.default_cache_behavior.response_headers_policy_id :
          can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", dist_config.default_cache_behavior.response_headers_policy_id)) ?
          dist_config.default_cache_behavior.response_headers_policy_id :
          contains(keys(local.aws_managed_response_headers_policy_ids), dist_config.default_cache_behavior.response_headers_policy_id) ?
          local.aws_managed_response_headers_policy_ids[dist_config.default_cache_behavior.response_headers_policy_id] :
          dist_config.default_cache_behavior.response_headers_policy_id
        )


        function_associations = {
          for event_type, assoc in lookup(dist_config.default_cache_behavior, "function_associations", lookup(dist_config.default_cache_behavior, "function_association", {})) :
          event_type => {
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
          # Otherwise, use TTL from behavior.ttl or default to 0 if ttl block is missing
          min_ttl                    = lookup(behavior, "cache_policy_id", null) != null ? 0 : try(behavior.ttl.min_ttl, 0)
          default_ttl                = lookup(behavior, "cache_policy_id", null) != null ? 0 : try(behavior.ttl.default_ttl, 0)
          max_ttl                    = lookup(behavior, "cache_policy_id", null) != null ? 0 : try(behavior.ttl.max_ttl, 0)
          compress                   = lookup(behavior, "compress", false)
          cache_policy_id            = lookup(behavior, "cache_policy_id", null)
          origin_request_policy_id   = lookup(behavior, "origin_request_policy_id", null)
          response_headers_policy_id = lookup(behavior, "response_headers_policy_id", null)

          use_forwarded_values     = lookup(behavior, "use_forwarded_values", false)
          query_string             = lookup(behavior, "query_string", false)
          headers                  = lookup(behavior, "headers", [])
          cookies_forward          = lookup(behavior, "cookies_forward", "none")

          # Resolved policy IDs - dynamically resolve custom, AWS managed, ARN, and UUID references
          resolved_cache_policy_id = (
            lookup(behavior, "cache_policy_id", null) == null ? null :
            contains(keys(local.cache_policy_ids_map), behavior.cache_policy_id) ?
            local.cache_policy_ids_map[behavior.cache_policy_id] :
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
            contains(keys(local.origin_request_policy_ids_map), behavior.origin_request_policy_id) ?
            local.origin_request_policy_ids_map[behavior.origin_request_policy_id] :
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
            contains(keys(local.response_headers_policy_ids_map), behavior.response_headers_policy_id) ?
            local.response_headers_policy_ids_map[behavior.response_headers_policy_id] :
            startswith(behavior.response_headers_policy_id, "arn:") ?
            behavior.response_headers_policy_id :
            can(regex("^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$", behavior.response_headers_policy_id)) ?
            behavior.response_headers_policy_id :
            contains(keys(local.aws_managed_response_headers_policy_ids), behavior.response_headers_policy_id) ?
            local.aws_managed_response_headers_policy_ids[behavior.response_headers_policy_id] :
            behavior.response_headers_policy_id
          )


          function_associations = {
            for event_type, assoc in lookup(behavior, "function_associations", lookup(behavior, "function_association", {})) :
            event_type => {
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

