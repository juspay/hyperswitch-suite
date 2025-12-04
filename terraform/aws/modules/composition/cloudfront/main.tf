# ============================================================================
# CloudFront Module - Main Implementation
# ============================================================================

# Create S3 bucket for CloudFront logs if enabled and requested
module "log_bucket" {
  count = var.enable_logging && var.create_log_bucket ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket = local.log_bucket_config.bucket_name
}

# Origin Access Controls
resource "aws_cloudfront_origin_access_control" "this" {
  count = local.create ? length(var.origin_access_controls) : 0

  name                              = var.origin_access_controls[count.index].name
  description                       = var.origin_access_controls[count.index].description
  origin_access_control_origin_type = var.origin_access_controls[count.index].origin_access_control_origin_type
  signing_behavior                  = var.origin_access_controls[count.index].signing_behavior
  signing_protocol                  = var.origin_access_controls[count.index].signing_protocol
}

# CloudFront Distributions
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.0"

  for_each = var.distributions

  # Basic distribution configuration
  comment             = lookup(each.value, "comment", "${var.project_name}-${each.key}-${var.environment}")
  enabled             = lookup(each.value, "enabled", true)
  default_root_object = lookup(each.value, "default_root_object", "index.html")
  price_class         = lookup(each.value, "price_class", "PriceClass_All")
  is_ipv6_enabled     = true
  http_version        = "http2and3"

  # Origins configuration
  origin = {
    for idx, origin_config in local.processed_origins[each.key] :
    origin_config.origin_id => merge(
      {
        domain_name              = origin_config.resolved_domain_name
        origin_path              = lookup(origin_config, "origin_path", "")
        origin_access_control_id = lookup(origin_config, "origin_access_control_id", null)
      },
      origin_config.type != "s3" ? {
        custom_origin_config = {
          http_port                = lookup(origin_config.custom_origin_config, "http_port", 80)
          https_port               = lookup(origin_config.custom_origin_config, "https_port", 443)
          origin_protocol_policy   = lookup(origin_config.custom_origin_config, "origin_protocol_policy", "https-only")
          origin_ssl_protocols     = lookup(origin_config.custom_origin_config, "origin_ssl_protocols", ["TLSv1.2"])
          origin_keepalive_timeout = 5
          origin_read_timeout      = 30
        }
      } : {}
    )
  }

  # Default cache behavior
  default_cache_behavior = {
    target_origin_id       = local.processed_cache_behaviors[each.key].default.target_origin_id
    viewer_protocol_policy = local.processed_cache_behaviors[each.key].default.viewer_protocol_policy

    allowed_methods = local.processed_cache_behaviors[each.key].default.allowed_methods
    cached_methods  = local.processed_cache_behaviors[each.key].default.cached_methods
    compress        = local.processed_cache_behaviors[each.key].default.compress

    cache_policy_id            = local.processed_cache_behaviors[each.key].default.cache_policy_id
    origin_request_policy_id   = local.processed_cache_behaviors[each.key].default.origin_request_policy_id
    response_headers_policy_id = local.processed_cache_behaviors[each.key].default.response_headers_policy_id

    min_ttl     = local.processed_cache_behaviors[each.key].default.min_ttl
    default_ttl = local.processed_cache_behaviors[each.key].default.default_ttl
    max_ttl     = local.processed_cache_behaviors[each.key].default.max_ttl

    use_forwarded_values = false

    lambda_function_association = local.processed_cache_behaviors[each.key].default.lambda_function_associations
    function_association        = local.processed_cache_behaviors[each.key].default.function_associations
  }

  # Ordered cache behaviors
  ordered_cache_behavior = [
    for idx, behavior in local.processed_cache_behaviors[each.key].ordered : {
      path_pattern           = behavior.path_pattern
      target_origin_id       = behavior.target_origin_id
      viewer_protocol_policy = behavior.viewer_protocol_policy

      allowed_methods = behavior.allowed_methods
      cached_methods  = behavior.cached_methods
      compress        = behavior.compress

      cache_policy_id            = behavior.cache_policy_id
      origin_request_policy_id   = behavior.origin_request_policy_id
      response_headers_policy_id = behavior.response_headers_policy_id

      min_ttl     = behavior.min_ttl
      default_ttl = behavior.default_ttl
      max_ttl     = behavior.max_ttl

      use_forwarded_values = false

      lambda_function_association = behavior.lambda_function_associations
      function_association        = behavior.function_associations
    }
  ]

  # Logging configuration
  logging_config = var.enable_logging && local.log_bucket_config != null ? {
    bucket          = local.log_bucket_config.bucket_domain_name
    prefix          = lookup(var.log_bucket, "prefix", "cloudfront/")
    include_cookies = false
  } : {}

  # Custom error responses
  custom_error_response = lookup(each.value, "custom_error_responses", [])

  # Geo restrictions (v6 uses restrictions block)
  restrictions = {
    geo_restriction = lookup(each.value, "geo_restriction", {
      restriction_type = "none"
      locations        = []
    })
  }

  # Web ACL
  web_acl_id = lookup(each.value, "web_acl_id", null)

  # Viewer certificate (use default CloudFront certificate for now)
  viewer_certificate = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Disable automatic OAC creation by the module
  # OACs are managed at the composition level instead
  origin_access_control = {}

  # Add distribution-specific name to tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${each.key}-${var.environment}"
    }
  )
}

# CloudFront Functions
resource "aws_cloudfront_function" "this" {
  count = local.create ? length(var.cloudfront_functions) : 0

  name    = var.cloudfront_functions[count.index].name
  runtime = var.cloudfront_functions[count.index].runtime
  comment = lookup(var.cloudfront_functions[count.index], "comment", null)
  code    = var.cloudfront_functions[count.index].code
  publish = lookup(var.cloudfront_functions[count.index], "publish", true)

}

# Response Headers Policies
resource "aws_cloudfront_response_headers_policy" "this" {
  count = local.create ? length(var.response_headers_policies) : 0

  name    = var.response_headers_policies[count.index].name
  comment = lookup(var.response_headers_policies[count.index], "comment", null)

  # CORS configuration
  dynamic "cors_config" {
    for_each = var.response_headers_policies[count.index].cors_config != null ? [var.response_headers_policies[count.index].cors_config] : []
    
    content {
      origin_override = true
      access_control_allow_credentials = cors_config.value.access_control_allow_credentials
      access_control_allow_headers {
        items = cors_config.value.access_control_allow_headers
      }
      access_control_allow_methods {
        items = cors_config.value.access_control_allow_methods
      }
      access_control_allow_origins {
        items = cors_config.value.access_control_allow_origins
      }
      dynamic "access_control_expose_headers" {
        for_each = length(lookup(cors_config.value, "access_control_expose_headers", [])) > 0 ? [cors_config.value.access_control_expose_headers] : []
        content {
          items = access_control_expose_headers.value
        }
      }
      access_control_max_age_sec = cors_config.value.access_control_max_age_sec
    }
  }

  # Security headers configuration
  dynamic "security_headers_config" {
    for_each = lookup(var.response_headers_policies[count.index], "security_headers_config", null) != null ? [var.response_headers_policies[count.index].security_headers_config] : []

    content {
      dynamic "content_security_policy" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "content_security_policy", null) != null ? [lookup(security_headers_config.value, "content_security_policy", null)] : []) : []
        content {
          content_security_policy = content_security_policy.value.content_security_policy
          override                = content_security_policy.value.override
        }
      }

      dynamic "content_type_options" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "content_type_options", null) != null ? [lookup(security_headers_config.value, "content_type_options", null)] : []) : []
        content {
          override = content_type_options.value.override
        }
      }

      dynamic "frame_options" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "frame_options", null) != null ? [lookup(security_headers_config.value, "frame_options", null)] : []) : []
        content {
          frame_option = frame_options.value.frame_option
          override     = frame_options.value.override
        }
      }

      dynamic "referrer_policy" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "referrer_policy", null) != null ? [lookup(security_headers_config.value, "referrer_policy", null)] : []) : []
        content {
          referrer_policy = referrer_policy.value.referrer_policy
          override        = referrer_policy.value.override
        }
      }

      dynamic "xss_protection" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "xss_protection", null) != null ? [lookup(security_headers_config.value, "xss_protection", null)] : []) : []
        content {
          mode_block = xss_protection.value.mode_block
          override   = xss_protection.value.override
          protection = xss_protection.value.protection
          report_uri = lookup(xss_protection.value, "report_uri", null)
        }
      }

      dynamic "strict_transport_security" {
        for_each = security_headers_config.value != null ? (lookup(security_headers_config.value, "strict_transport_security", null) != null ? [lookup(security_headers_config.value, "strict_transport_security", null)] : []) : []
        content {
          access_control_max_age_sec = strict_transport_security.value.access_control_max_age_sec
          override                   = strict_transport_security.value.override
          include_subdomains         = lookup(strict_transport_security.value, "include_subdomains", null)
          preload                    = lookup(strict_transport_security.value, "preload", null)
        }
      }
    }
  }

  # Custom headers configuration
  dynamic "custom_headers_config" {
    for_each = lookup(var.response_headers_policies[count.index], "custom_headers_config", null) != null ? [var.response_headers_policies[count.index].custom_headers_config] : []
    
    content {
      dynamic "items" {
        for_each = custom_headers_config.value.items
        
        content {
          header   = items.value.header
          override = items.value.override
          value    = items.value.value
        }
      }
    }
  }

  # Remove headers configuration
  dynamic "remove_headers_config" {
    for_each = lookup(var.response_headers_policies[count.index], "remove_headers_config", null) != null ? [var.response_headers_policies[count.index].remove_headers_config] : []
    
    content {
      dynamic "items" {
        for_each = remove_headers_config.value.items
        
        content {
          header = items.value.header
        }
      }
    }
  }

}

# ============================================================================
# S3 Bucket Policies for OAC
# ============================================================================

resource "aws_s3_bucket_policy" "oac_policy" {
  for_each = local.create ? {
    for dist_name, origins in local.s3_bucket_origins :
    dist_name => origins if length(origins) > 0
  } : {}

  bucket = each.value[0].bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for origin in each.value : {
        Sid       = "AllowCloudFrontServicePrincipal-${origin.origin_id}"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = ["s3:GetObject"]
        Resource  = "${origin.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront[each.key].cloudfront_distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [module.cloudfront]
}

# ============================================================================
# CloudFront Invalidation
# ============================================================================

resource "null_resource" "cloudfront_invalidation" {
  for_each = local.create ? {
    for dist_name, dist_config in var.distributions :
    dist_name => dist_config
    if lookup(dist_config, "invalidation", null) != null && lookup(lookup(dist_config, "invalidation", {}), "enabled", false)
  } : {}

  triggers = {
    distribution_id = module.cloudfront[each.key].cloudfront_distribution_id
    version         = each.value.invalidation.version
    paths           = join(",", each.value.invalidation.paths)
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws cloudfront create-invalidation \
        --distribution-id ${module.cloudfront[each.key].cloudfront_distribution_id} \
        --paths ${join(" ", each.value.invalidation.paths)}
    EOT
  }

  depends_on = [module.cloudfront]
}