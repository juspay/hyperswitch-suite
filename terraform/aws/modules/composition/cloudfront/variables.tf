# ============================================================================
# Variables - Input configuration
# ============================================================================

variable "create" {
  description = "Controls if resources should be created (affects nearly all resources)"
  type        = bool
  default     = true
}

# ============================================================================
# Environment & Naming
# ============================================================================

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# CloudFront Distributions Configuration
# ============================================================================

variable "distributions" {
  description = "Map of CloudFront distributions to create"
  type = map(object({
    # Origins configuration
    origins = list(object({
      origin_id                  = string
      type                       = string # s3, alb, custom, vpc_origin
      domain_name                = optional(string)
      s3_bucket_domain_name      = optional(string)
      s3_bucket_id              = optional(string)
      s3_bucket_arn             = optional(string)
      origin_path               = optional(string)

      # Origin Access Control
      origin_access_control_id  = optional(string)
      apply_bucket_policy       = optional(bool, true)

      # Custom origin configuration
      custom_origin_config = optional(object({
        http_port              = number
        https_port             = number
        origin_protocol_policy = string
        origin_ssl_protocols   = optional(list(string), ["TLSv1.2"])
      }))
    }))

    # Default cache behavior
    default_cache_behavior = object({
      target_origin_id = string
      allowed_methods  = list(string)
      cached_methods   = list(string)

      viewer_protocol_policy = string

      # Cache TTL configuration
      ttl = object({
        min_ttl    = number
        default_ttl = number
        max_ttl    = number
      })

      # Optional configuration
      compress = optional(bool, false)
      cache_policy_id = optional(string)
      origin_request_policy_id = optional(string)
      response_headers_policy_id = optional(string)

      # Lambda@Edge associations
      lambda_function_associations = optional(list(object({
        event_type   = string
        lambda_arn   = string
        include_body = optional(bool)
      })), [])

      # CloudFront Function associations
      function_associations = optional(list(object({
        event_type   = string
        function_arn = string
      })), [])
    }),

    # Ordered cache behaviors (optional)
    ordered_cache_behaviors = optional(list(object({
      path_pattern = string
      target_origin_id = string

      allowed_methods = list(string)
      cached_methods  = list(string)

      viewer_protocol_policy = string

      # Cache TTL configuration
      ttl = object({
        min_ttl    = number
        default_ttl = number
        max_ttl    = number
      })

      # Optional configuration
      compress = optional(bool, false)
      cache_policy_id = optional(string)
      origin_request_policy_id = optional(string)
      response_headers_policy_id = optional(string)

      # Lambda@Edge associations
      lambda_function_associations = optional(list(object({
        event_type   = string
        lambda_arn   = string
        include_body = optional(bool)
      })), [])

      # CloudFront Function associations
      function_associations = optional(list(object({
        event_type   = string
        function_arn = string
      })), [])
    })), [])

    # Custom error responses (optional)
    custom_error_responses = optional(list(object({
      error_caching_min_ttl = optional(number)
      error_code            = number
      response_code         = optional(number)
      response_page_path    = optional(string)
    })), [])

    # Additional configuration
    default_root_object = optional(string, "index.html")
    price_class        = optional(string, "PriceClass_All")
    enabled            = optional(bool, true)
    comment            = optional(string)

    # Geo restrictions
    geo_restriction = optional(object({
      restriction_type = optional(string, "none")
      locations        = optional(list(string), [])
    }), {})

    # Invalidation configuration
    invalidation = optional(object({
      enabled = bool
      version = string
      paths   = list(string)
    }))
  }))

  # Validation rules
  validation {
    condition     = length(var.distributions) <= 15
    error_message = "Number of distributions cannot exceed 15 for manageability."
  }

  validation {
    condition = alltrue([
      for name, dist in var.distributions :
      length(dist.ordered_cache_behaviors) <= 25
    ])
    error_message = "Number of cache behaviors per distribution cannot exceed 25."
  }

  validation {
    condition = alltrue([
      for name, dist in var.distributions :
      length(dist.origins) > 0
    ])
    error_message = "Each distribution must have at least one origin."
  }
}

# ============================================================================
# S3 Logging Configuration
# ============================================================================

variable "enable_logging" {
  description = "Enable CloudFront access logging to S3"
  type        = bool
  default     = true
}

variable "create_log_bucket" {
  description = "Create S3 bucket for CloudFront logs"
  type        = bool
  default     = false
}

variable "log_bucket" {
  description = "Existing S3 bucket for CloudFront access logs (if create_log_bucket is false)"
  type = object({
    bucket_name = string
    bucket_arn  = string
    bucket_domain_name = string
    bucket_regional_domain_name = optional(string)
    prefix      = optional(string)
  })
  default = null
}

# ============================================================================
# Origin Access Controls (OAC)
# ============================================================================

variable "origin_access_controls" {
  description = "Map of Origin Access Control resources to create"
  type = list(object({
    name                              = string
    description                       = string
    origin_access_control_origin_type = string
    signing_behavior                  = string
    signing_protocol                  = string
  }))
  default = []
}

# ============================================================================
# ============================================================================
# CloudFront Functions (Lightweight)
# ============================================================================

variable "cloudfront_functions" {
  description = "Map of CloudFront Functions to create"
  type = list(object({
    name    = string
    runtime = optional(string, "cloudfront-js-1.0")
    comment = optional(string)
    code    = string
    publish = optional(bool, true)
  }))
  default = []
}

# ============================================================================
# Response Headers Policies
# ============================================================================

variable "response_headers_policies" {
  description = "Map of response headers policies to create"
  type = list(object({
    name    = string
    comment = optional(string)

    # CORS configuration
    cors_config = optional(object({
      access_control_allow_credentials = bool
      access_control_allow_headers     = list(string)
      access_control_allow_methods     = list(string)
      access_control_allow_origins     = list(string)
      access_control_expose_headers    = optional(list(string), [])
      access_control_max_age_sec       = optional(number)
    }))

    # Security headers configuration
    security_headers_config = optional(object({
      content_security_policy = optional(object({
        content_security_policy = string
        override                = bool
      }))
      content_type_options = optional(object({
        override = bool
      }))
      frame_options = optional(object({
        frame_option = string
        override     = bool
      }))
      referrer_policy = optional(object({
        referrer_policy = string
        override        = bool
      }))
      xss_protection = optional(object({
        mode_block = bool
        override   = bool
        protection = bool
        report_uri = optional(string)
      }))
      strict_transport_security = optional(object({
        access_control_max_age_sec = number
        override                   = bool
        include_subdomains         = optional(bool)
        preload                    = optional(bool)
      }))
    }))

    # Custom headers configuration
    custom_headers_config = optional(object({
      items = list(object({
        header   = string
        override = bool
        value    = string
      }))
    }))

    # Remove headers configuration
    remove_headers_config = optional(object({
      items = list(object({
        header = string
      }))
    }))
  }))
  default = []
}
