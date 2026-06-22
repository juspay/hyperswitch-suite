locals {
  create = var.create
}

data "aws_cloudfront_cache_policy" "managed" {
  for_each = toset(var.managed_cache_policies)
  name     = each.value
}

data "aws_cloudfront_origin_request_policy" "managed" {
  for_each = toset(var.managed_origin_request_policies)
  name     = each.value
}

data "aws_cloudfront_response_headers_policy" "managed" {
  for_each = toset(var.managed_response_headers_policies)
  name     = each.value
}

resource "aws_cloudfront_cache_policy" "custom" {
  for_each = local.create ? var.custom_cache_policies : {}

  name        = each.value.name
  comment     = each.value.comment
  default_ttl = each.value.default_ttl
  max_ttl     = each.value.max_ttl
  min_ttl     = each.value.min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = each.value.enable_accept_encoding_brotli
    enable_accept_encoding_gzip   = each.value.enable_accept_encoding_gzip

    headers_config {
      header_behavior = each.value.headers_config_header_behavior
      dynamic "headers" {
        for_each = length(each.value.headers_config_headers) > 0 ? [each.value.headers_config_headers] : []
        content {
          items = headers.value
        }
      }
    }

    cookies_config {
      cookie_behavior = each.value.cookies_config_cookie_behavior
      dynamic "cookies" {
        for_each = length(each.value.cookies_config_cookies) > 0 ? [each.value.cookies_config_cookies] : []
        content {
          items = cookies.value
        }
      }
    }

    query_strings_config {
      query_string_behavior = each.value.query_strings_config_query_string_behavior
      dynamic "query_strings" {
        for_each = length(each.value.query_strings_config_query_strings) > 0 ? [each.value.query_strings_config_query_strings] : []
        content {
          items = query_strings.value
        }
      }
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "custom" {
  for_each = local.create ? var.custom_origin_request_policies : {}

  name    = each.value.name
  comment = each.value.comment

  headers_config {
    header_behavior = each.value.headers_config_header_behavior
    dynamic "headers" {
      for_each = length(each.value.headers_config_headers) > 0 ? [each.value.headers_config_headers] : []
      content {
        items = headers.value
      }
    }
  }

  cookies_config {
    cookie_behavior = each.value.cookies_config_cookie_behavior
    dynamic "cookies" {
      for_each = length(each.value.cookies_config_cookies) > 0 ? [each.value.cookies_config_cookies] : []
      content {
        items = cookies.value
      }
    }
  }

  query_strings_config {
    query_string_behavior = each.value.query_strings_config_query_string_behavior
    dynamic "query_strings" {
      for_each = length(each.value.query_strings_config_query_strings) > 0 ? [each.value.query_strings_config_query_strings] : []
      content {
        items = query_strings.value
      }
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "custom" {
  for_each = local.create ? var.custom_response_headers_policies : {}

  name    = each.value.name
  comment = each.value.comment

  dynamic "cors_config" {
    for_each = each.value.cors_config != null ? [each.value.cors_config] : []
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
        for_each = length(lookup(cors_config.value, "access_control_expose_headers", [])) > 0 ? [lookup(cors_config.value, "access_control_expose_headers", [])] : []
        content {
          items = access_control_expose_headers.value
        }
      }

      access_control_max_age_sec = lookup(cors_config.value, "access_control_max_age_sec", null)
    }
  }

  dynamic "security_headers_config" {
    for_each = each.value.security_headers_config != null ? [each.value.security_headers_config] : []
    content {
      content_type_options {
        override = lookup(security_headers_config.value, "content_type_options_override", false)
      }

      dynamic "content_security_policy" {
        for_each = lookup(security_headers_config.value, "content_security_policy", null) != null ? [security_headers_config.value.content_security_policy] : []
        content {
          content_security_policy = content_security_policy.value.policy
          override                = lookup(content_security_policy.value, "override", false)
        }
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

  dynamic "remove_headers_config" {
    for_each = each.value.remove_headers_config != null ? [each.value.remove_headers_config] : []
    content {
      dynamic "items" {
        for_each = remove_headers_config.value.items
        content {
          header = items.value
        }
      }
    }
  }

  dynamic "custom_headers_config" {
    for_each = each.value.custom_headers_config != null ? [each.value.custom_headers_config] : []
    content {
      dynamic "items" {
        for_each = custom_headers_config.value.items
        content {
          header   = items.value.header
          value    = items.value.value
          override = items.value.override
        }
      }
    }
  }
}
