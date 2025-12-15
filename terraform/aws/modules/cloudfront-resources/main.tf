# ============================================================================
# CloudFront Resources Module - Creates shared CloudFront prerequisite resources
# Can be used by multiple composition modules (cloudfront, envoy-proxy, etc.)
# ============================================================================

# CloudFront Functions
resource "aws_cloudfront_function" "this" {
  for_each = local.create ? var.cloudfront_functions : {}

  name    = each.value.name
  runtime = each.value.runtime
  comment = lookup(each.value, "comment", null)
  code    = each.value.code
  publish = lookup(each.value, "publish", true)
}

# Response Headers Policies
resource "aws_cloudfront_response_headers_policy" "this" {
  for_each = local.create ? var.response_headers_policies : {}

  name    = each.value.name
  comment = lookup(each.value, "comment", null)

  # CORS configuration
  dynamic "cors_config" {
    for_each = each.value.cors_config != null ? [each.value.cors_config] : []

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

  # Security headers (simplified for brevity - can be extended)
  dynamic "security_headers_config" {
    for_each = lookup(each.value, "security_headers_config", null) != null ? [each.value.security_headers_config] : []
    content {
      # Security headers configuration would go here
      # For now, we'll keep it simple as the current config only uses CORS
    }
  }
}

# Cache Policies
resource "aws_cloudfront_cache_policy" "this" {
  for_each = local.create ? var.cache_policies : {}

  name        = each.value.name
  comment     = lookup(each.value, "comment", null)
  default_ttl = lookup(each.value, "default_ttl", null)
  max_ttl     = lookup(each.value, "max_ttl", null)
  min_ttl     = lookup(each.value, "min_ttl", null)

  # Cache key configuration
  dynamic "parameters_in_cache_key_and_forwarded_to_origin" {
    for_each = lookup(each.value, "parameters_in_cache_key_and_forwarded_to_origin", null) != null ? [each.value.parameters_in_cache_key_and_forwarded_to_origin] : []
    content {
      enable_accept_encoding_brotli = lookup(parameters_in_cache_key_and_forwarded_to_origin.value, "enable_accept_encoding_brotli", false)
      enable_accept_encoding_gzip = lookup(parameters_in_cache_key_and_forwarded_to_origin.value, "enable_accept_encoding_gzip", true)

      dynamic "headers_config" {
        for_each = lookup(parameters_in_cache_key_and_forwarded_to_origin.value, "headers_config", null) != null ? [parameters_in_cache_key_and_forwarded_to_origin.value.headers_config] : []
        content {
          header_behavior = headers_config.value.header_behavior
          dynamic "headers" {
            for_each = lookup(headers_config.value, "headers", null) != null ? [headers_config.value.headers] : []
            content {
              items = headers.value
            }
          }
        }
      }

      dynamic "cookies_config" {
        for_each = lookup(parameters_in_cache_key_and_forwarded_to_origin.value, "cookies_config", null) != null ? [parameters_in_cache_key_and_forwarded_to_origin.value.cookies_config] : []
        content {
          cookie_behavior = cookies_config.value.cookie_behavior
          dynamic "cookies" {
            for_each = lookup(cookies_config.value, "cookies", null) != null && length(lookup(cookies_config.value, "cookies", [])) > 0 ? [cookies_config.value.cookies] : []
            content {
              items = cookies.value
            }
          }
        }
      }

      dynamic "query_strings_config" {
        for_each = lookup(parameters_in_cache_key_and_forwarded_to_origin.value, "query_strings_config", null) != null ? [parameters_in_cache_key_and_forwarded_to_origin.value.query_strings_config] : []
        content {
          query_string_behavior = query_strings_config.value.query_string_behavior
          dynamic "query_strings" {
            for_each = lookup(query_strings_config.value, "query_strings", null) != null && length(lookup(query_strings_config.value, "query_strings", [])) > 0 ? [query_strings_config.value.query_strings] : []
            content {
              items = query_strings.value
            }
          }
        }
      }
    }
  }
}

# Origin Request Policies
resource "aws_cloudfront_origin_request_policy" "this" {
  for_each = local.create ? var.origin_request_policies : {}

  name    = each.value.name
  comment = lookup(each.value, "comment", null)

  dynamic "headers_config" {
    for_each = lookup(each.value, "headers_config", null) != null ? [each.value.headers_config] : []
    content {
      header_behavior = headers_config.value.header_behavior
      dynamic "headers" {
        for_each = lookup(headers_config.value, "headers", null) != null && length(lookup(headers_config.value, "headers", [])) > 0 ? [headers_config.value.headers] : []
        content {
          items = headers.value
        }
      }
    }
  }

  dynamic "cookies_config" {
    for_each = lookup(each.value, "cookies_config", null) != null ? [each.value.cookies_config] : []
    content {
      cookie_behavior = cookies_config.value.cookie_behavior
      dynamic "cookies" {
        for_each = lookup(cookies_config.value, "cookies", null) != null && length(lookup(cookies_config.value, "cookies", [])) > 0 ? [cookies_config.value.cookies] : []
        content {
          items = cookies.value
        }
      }
    }
  }

  dynamic "query_strings_config" {
    for_each = lookup(each.value, "query_strings_config", null) != null ? [each.value.query_strings_config] : []
    content {
      query_string_behavior = query_strings_config.value.query_string_behavior
      dynamic "query_strings" {
        for_each = lookup(query_strings_config.value, "query_strings", null) != null && length(lookup(query_strings_config.value, "query_strings", [])) > 0 ? [query_strings_config.value.query_strings] : []
        content {
          items = query_strings.value
        }
      }
    }
  }
}