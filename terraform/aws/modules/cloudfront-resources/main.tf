# ============================================================================
# CloudFront Resources Module - Creates shared CloudFront prerequisite resources
# Can be used by multiple composition modules (cloudfront, envoy-proxy, etc.)
# ============================================================================

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

  # Security headers (simplified for brevity - can be extended)
  dynamic "security_headers_config" {
    for_each = lookup(var.response_headers_policies[count.index], "security_headers_config", null) != null ? [var.response_headers_policies[count.index].security_headers_config] : []
    content {
      # Security headers configuration would go here
      # For now, we'll keep it simple as the current config only uses CORS
    }
  }
}

# Cache Policies
resource "aws_cloudfront_cache_policy" "this" {
  count = local.create ? length(var.cache_policies) : 0

  name        = var.cache_policies[count.index].name
  comment     = lookup(var.cache_policies[count.index], "comment", null)
  default_ttl = lookup(var.cache_policies[count.index], "default_ttl", null)
  max_ttl     = lookup(var.cache_policies[count.index], "max_ttl", null)
  min_ttl     = lookup(var.cache_policies[count.index], "min_ttl", null)

  # Cache key configuration
  dynamic "parameters_in_cache_key_and_forwarded_to_origin" {
    for_each = lookup(var.cache_policies[count.index], "parameters_in_cache_key_and_forwarded_to_origin", null) != null ? [var.cache_policies[count.index].parameters_in_cache_key_and_forwarded_to_origin] : []
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
  count = local.create ? length(var.origin_request_policies) : 0

  name    = var.origin_request_policies[count.index].name
  comment = lookup(var.origin_request_policies[count.index], "comment", null)

  dynamic "headers_config" {
    for_each = lookup(var.origin_request_policies[count.index], "headers_config", null) != null ? [var.origin_request_policies[count.index].headers_config] : []
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
    for_each = lookup(var.origin_request_policies[count.index], "cookies_config", null) != null ? [var.origin_request_policies[count.index].cookies_config] : []
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
    for_each = lookup(var.origin_request_policies[count.index], "query_strings_config", null) != null ? [var.origin_request_policies[count.index].query_strings_config] : []
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