# ============================================================================
# CloudFront Module - Main Implementation (Self-contained)
# Creates distributions and all related resources (functions, policies, etc.)
# ============================================================================

# CloudFront Functions
resource "aws_cloudfront_function" "this" {
  for_each = local.create ? var.cloudfront_functions : {}

  name    = each.value.name
  runtime = each.value.runtime
  comment = lookup(each.value, "comment", "")
  publish = lookup(each.value, "publish", true)
  code    = each.value.code
}

# Response Headers Policies
resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = local.create ? var.response_headers_policies : {}

  name    = each.value.name
  comment = lookup(each.value, "comment", "")

  dynamic "cors_config" {
    for_each = lookup(each.value, "cors_config", null) != null ? [each.value.cors_config] : []
    content {
      access_control_allow_credentials = cors_config.value.access_control_allow_credentials
      origin_override                  = lookup(cors_config.value, "origin_override", false)

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
        for_each = lookup(cors_config.value, "access_control_expose_headers", null) != null ? [cors_config.value.access_control_expose_headers] : []
        content {
          items = access_control_expose_headers.value
        }
      }

      access_control_max_age_sec = lookup(cors_config.value, "access_control_max_age_sec", null)
    }
  }

  dynamic "security_headers_config" {
    for_each = lookup(each.value, "security_headers_config", null) != null ? [each.value.security_headers_config] : []
    content {
      dynamic "content_security_policy" {
        for_each = lookup(security_headers_config.value, "content_security_policy", null) != null ? [security_headers_config.value.content_security_policy] : []
        content {
          content_security_policy = content_security_policy.value
          override                = lookup(security_headers_config.value, "content_security_policy_override", false)
        }
      }
      content_type_options {
        override = lookup(security_headers_config.value, "content_type_options_override", false)
      }
      frame_options {
        frame_option = lookup(security_headers_config.value, "frame_option", "DENY")
        override     = lookup(security_headers_config.value, "frame_options_override", false)
      }
      referrer_policy {
        referrer_policy = lookup(security_headers_config.value, "referrer_policy", "strict-origin-when-cross-origin")
        override        = lookup(security_headers_config.value, "referrer_policy_override", false)
      }
      strict_transport_security {
        access_control_max_age_sec = lookup(security_headers_config.value, "strict_transport_security_max_age_sec", 31536000)
        include_subdomains         = lookup(security_headers_config.value, "include_subdomains", true)
        preload                    = lookup(security_headers_config.value, "preload", true)
        override                   = lookup(security_headers_config.value, "strict_transport_security_override", false)
      }
      xss_protection {
        mode_block = lookup(security_headers_config.value, "xss_protection_mode_block", true)
        protection = lookup(security_headers_config.value, "xss_protection", true)
        override   = lookup(security_headers_config.value, "xss_protection_override", false)
        report_uri = lookup(security_headers_config.value, "xss_protection_report_uri", "")
      }
    }
  }
}

# Cache Policies
resource "aws_cloudfront_cache_policy" "this" {
  for_each = local.create ? var.cache_policies : {}

  name        = each.value.name
  comment     = lookup(each.value, "comment", "")
  default_ttl = lookup(each.value, "default_ttl", 86400)
  max_ttl     = lookup(each.value, "max_ttl", 31536000)
  min_ttl     = lookup(each.value, "min_ttl", 1)

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = lookup(each.value, "enable_accept_encoding_brotli", false)
    enable_accept_encoding_gzip   = lookup(each.value, "enable_accept_encoding_gzip", true)

    headers_config {
      header_behavior = lookup(each.value, "headers_config.header_behavior", "none")
      headers {
        items = lookup(each.value, "headers_config.headers", [])
      }
    }

    cookies_config {
      cookie_behavior = lookup(each.value, "cookies_config.cookie_behavior", "none")
      cookies {
        items = lookup(each.value, "cookies_config.cookies", [])
      }
    }

    query_strings_config {
      query_string_behavior = lookup(each.value, "query_strings_config.query_string_behavior", "none")
      query_strings {
        items = lookup(each.value, "query_strings_config.query_strings", [])
      }
    }
  }
}

# Origin Request Policies
resource "aws_cloudfront_origin_request_policy" "this" {
  for_each = local.create ? var.origin_request_policies : {}

  name    = each.value.name
  comment = lookup(each.value, "comment", "")

  headers_config {
    header_behavior = lookup(each.value, "headers_config.header_behavior", "none")
    headers {
      items = lookup(each.value, "headers_config.headers", [])
    }
  }

  cookies_config {
    cookie_behavior = lookup(each.value, "cookies_config.cookie_behavior", "none")
    cookies {
      items = lookup(each.value, "cookies_config.cookies", [])
    }
  }

  query_strings_config {
    query_string_behavior = lookup(each.value, "query_strings_config.query_string_behavior", "none")
    query_strings {
      items = lookup(each.value, "query_strings_config.query_strings", [])
    }
  }
}

# Create S3 bucket for CloudFront logs if enabled and requested
module "log_bucket" {
  count = var.enable_logging && var.create_log_bucket ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket = local.log_bucket_config.bucket_name
}

# ============================================================================
# VPC Origins for ALB
# ============================================================================

resource "aws_cloudfront_vpc_origin" "this" {
  for_each = local.vpc_origins_map

  vpc_origin_endpoint_config {
    name                   = each.value.name
    arn                    = each.value.alb_arn
    http_port              = each.value.http_port
    https_port             = each.value.https_port
    origin_protocol_policy = each.value.origin_protocol_policy

    origin_ssl_protocols {
      items    = each.value.origin_ssl_protocols.items
      quantity = each.value.origin_ssl_protocols.quantity
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = each.value.name
    }
  )
}

# CloudFront Distributions
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 4.2.0"

  for_each = local.all_distributions

  # Basic distribution configuration
  comment             = lookup(each.value, "comment", "${var.project_name}-${each.key}-${var.environment}")
  enabled             = lookup(each.value, "enabled", true)
  default_root_object = lookup(each.value, "default_root_object", "index.html")
  price_class         = lookup(each.value, "price_class", "PriceClass_All")
  is_ipv6_enabled     = true
  http_version        = "http2"

  create_origin_access_identity = length([for o in each.value.origins : o if lookup(o, "type", "") == "s3"]) > 0
  origin_access_identities = {
    for o in each.value.origins :
    o.origin_id => lookup(o, "origin_access_identity_comment", "OAI for ${o.origin_id} in ${each.key}")
    if lookup(o, "type", "") == "s3"
  }

  origin = {
    for origin in local.processed_origins[each.key] :
    origin.origin_id => merge(
      {
        domain_name = origin.resolved_domain_name
        origin_path = lookup(origin, "origin_path", "")
      },
      origin.type == "s3" ? {
        s3_origin_config = {
          # Reference the OAI by origin_id (key in origin_access_identities)
          origin_access_identity = origin.origin_id
        }
      } : {},
      origin.type == "vpc_origin" ? {
        vpc_origin_id = origin.vpc_origin_id
      } : {},
      origin.type == "alb" || origin.type == "custom" ? {
        custom_origin_config = origin.custom_origin_config
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

    # Policy IDs - resolved in locals.tf to support custom, AWS managed (short/full names), ARNs, and UUIDs
    cache_policy_id            = local.processed_cache_behaviors[each.key].default.resolved_cache_policy_id
    origin_request_policy_id   = local.processed_cache_behaviors[each.key].default.resolved_origin_request_policy_id
    response_headers_policy_id = local.processed_cache_behaviors[each.key].default.resolved_response_headers_policy_id

    min_ttl     = local.processed_cache_behaviors[each.key].default.min_ttl
    default_ttl = local.processed_cache_behaviors[each.key].default.default_ttl
    max_ttl     = local.processed_cache_behaviors[each.key].default.max_ttl

    use_forwarded_values = local.processed_cache_behaviors[each.key].default.use_forwarded_values
    query_string         = local.processed_cache_behaviors[each.key].default.query_string
    headers              = local.processed_cache_behaviors[each.key].default.headers
    cookies_forward      = local.processed_cache_behaviors[each.key].default.cookies_forward

    function_association = local.processed_cache_behaviors[each.key].default.function_associations
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

      # Policy IDs - resolved in locals.tf to support custom, AWS managed (short/full names), ARNs, and UUIDs
      cache_policy_id            = behavior.resolved_cache_policy_id
      origin_request_policy_id   = behavior.resolved_origin_request_policy_id
      response_headers_policy_id = behavior.resolved_response_headers_policy_id

      min_ttl     = behavior.min_ttl
      default_ttl = behavior.default_ttl
      max_ttl     = behavior.max_ttl

      use_forwarded_values = behavior.use_forwarded_values
      query_string         = behavior.query_string
      headers              = behavior.headers
      cookies_forward      = behavior.cookies_forward

      function_association = behavior.function_associations
    }
  ]

  logging_config = var.enable_logging && local.log_bucket_config != null ? {
    bucket          = local.log_bucket_config.bucket_domain_name
    prefix          = lookup(local.log_bucket_config, "prefix", "cloudfront/")
    include_cookies = false
  } : {}

  custom_error_response = length(lookup(each.value, "custom_error_responses", [])) > 0 ? each.value.custom_error_responses : [{}]

  geo_restriction = lookup(each.value, "geo_restriction", {
    restriction_type = "none"
    locations        = []
  })

  web_acl_id = lookup(each.value, "web_acl_id", null)

  aliases = lookup(each.value, "aliases", [])

  # Viewer certificate configuration
  # Note: When using cloudfront_default_certificate=true, AWS forces minimum_protocol_version to TLSv1
  # To enforce TLSv1.2+, you must use a custom ACM certificate.
  viewer_certificate = lookup(each.value, "viewer_certificate", null) != null ? {
    acm_certificate_arn            = each.value.viewer_certificate.acm_certificate_arn
    ssl_support_method             = lookup(each.value.viewer_certificate, "ssl_support_method", "sni-only")
    minimum_protocol_version       = lookup(each.value.viewer_certificate, "minimum_protocol_version", "TLSv1.2_2021")
    cloudfront_default_certificate = false
    } : {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1" # AWS enforces TLSv1 for default certificate
  }

  # Add distribution-specific name to tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${each.key}-${var.environment}"
    }
  )
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