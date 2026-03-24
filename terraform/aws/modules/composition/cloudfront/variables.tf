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
  description = "Environment name (dev, integ, prod, sbx)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sbx"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sbx."
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
    origins = any

    default_cache_behavior = object({
      target_origin_id = string
      allowed_methods  = list(string)
      cached_methods   = list(string)
      viewer_protocol_policy = string
      ttl = object({
        min_ttl     = number
        default_ttl = number
        max_ttl     = number
      })
      compress                   = optional(bool, false)
      cache_policy_id            = optional(string)
      origin_request_policy_id   = optional(string)
      response_headers_policy_id = optional(string)
      use_forwarded_values       = optional(bool, false)
      query_string               = optional(bool, false)
      headers                    = optional(list(string), [])
      cookies_forward            = optional(string, "none")
      lambda_function_associations = optional(any, [])
      function_associations      = optional(any, [])
    })

    ordered_cache_behaviors = optional(list(object({
      path_pattern     = string
      target_origin_id = string
      allowed_methods  = list(string)
      cached_methods   = list(string)
      viewer_protocol_policy = string
      ttl = object({
        min_ttl     = number
        default_ttl = number
        max_ttl     = number
      })
      compress                   = optional(bool, false)
      cache_policy_id            = optional(string)
      origin_request_policy_id   = optional(string)
      response_headers_policy_id = optional(string)
      use_forwarded_values       = optional(bool, false)
      query_string               = optional(bool, false)
      headers                    = optional(list(string), [])
      cookies_forward            = optional(string, "none")
      lambda_function_associations = optional(any, [])
      function_associations      = optional(any, [])
    })), [])

    custom_error_responses = optional(list(object({
      error_caching_min_ttl = optional(number)
      error_code            = number
      response_code         = optional(number)
      response_page_path    = optional(string)
    })), [])

    default_root_object = optional(string, "index.html")
    price_class         = optional(string, "PriceClass_All")
    enabled             = optional(bool, true)
    comment             = optional(string)
    web_acl_id          = optional(string, null)
    aliases             = optional(list(string), [])
    viewer_certificate  = optional(any, null)
    geo_restriction     = optional(any, {})
    invalidation        = optional(any, null)
  }))

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
  description = "Create S3 bucket for CloudFront logs (only used if enable_logging=true and log_bucket_arn is null)"
  type        = bool
  default     = false

  validation {
    condition     = !var.create_log_bucket || var.enable_logging
    error_message = "create_log_bucket can only be true when enable_logging is true."
  }
}

variable "log_bucket_arn" {
  description = "ARN of existing S3 bucket for CloudFront logs. If provided, this takes precedence over create_log_bucket."
  type        = string
  default     = null

  validation {
    condition     = var.log_bucket_arn == null || can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.log_bucket_arn))
    error_message = "log_bucket_arn must be a valid S3 bucket ARN."
  }

  validation {
    condition     = var.log_bucket_arn == null || var.enable_logging
    error_message = "log_bucket_arn should only be provided when enable_logging is true."
  }
}

variable "log_prefix" {
  description = "Prefix for CloudFront log files in S3 bucket"
  type        = string
  default     = "cloudfront/"
}

# ============================================================================
# CloudFront Shared Resources
# ============================================================================

variable "cloudfront_functions" {
  description = "Map of CloudFront Functions to create (keyed by function name)"
  type = map(object({
    name    = string
    runtime = optional(string, "cloudfront-js-1.0")
    comment = optional(string)
    code    = string
    publish = optional(bool, true)
  }))
  default = {}
}

variable "response_headers_policies" {
  description = "Map of response headers policies to create (keyed by policy name)"
  type = map(object({
    name    = string
    comment = optional(string)
    cors_config = optional(object({
      access_control_allow_credentials = bool
      access_control_allow_headers     = list(string)
      access_control_allow_methods     = list(string)
      access_control_allow_origins     = list(string)
      access_control_expose_headers    = optional(list(string), [])
      access_control_max_age_sec       = optional(number)
    }))
    security_headers_config = optional(any)
  }))
  default = {}
}

variable "cache_policies" {
  description = "Map of cache policies to create (keyed by policy name)"
  type = map(object({
    name        = string
    comment     = optional(string)
    default_ttl = optional(number)
    max_ttl     = optional(number)
    min_ttl     = optional(number)
    parameters_in_cache_key_and_forwarded_to_origin = optional(any)
  }))
  default = {}
}

variable "origin_request_policies" {
  description = "Map of origin request policies to create (keyed by policy name)"
  type = map(object({
    name    = string
    comment = optional(string)
    headers_config = optional(object({
      header_behavior = string
      headers         = optional(list(string), [])
    }))
    cookies_config = optional(object({
      cookie_behavior = string
      cookies         = optional(list(string), [])
    }))
    query_strings_config = optional(object({
      query_string_behavior = string
      query_strings         = optional(list(string), [])
    }))
  }))
  default = {}
}
