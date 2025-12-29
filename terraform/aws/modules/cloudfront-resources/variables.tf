# ============================================================================
# CloudFront Resources Module Variables
# ============================================================================

variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}

variable "cloudfront_functions" {
  description = "Map of CloudFront Functions to create (keyed by function name for stable resource tracking)"
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
  description = "Map of response headers policies to create (keyed by policy name for stable resource tracking)"
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
    security_headers_config = optional(any) # Can be extended for security headers
  }))
  default = {}
}

variable "cache_policies" {
  description = "Map of cache policies to create (keyed by policy name for stable resource tracking)"
  type = map(object({
    name        = string
    comment     = optional(string)
    default_ttl = optional(number)
    max_ttl     = optional(number)
    min_ttl     = optional(number)
    parameters_in_cache_key_and_forwarded_to_origin = optional(object({
      enable_accept_encoding_brotli = optional(bool, false)
      enable_accept_encoding_gzip  = optional(bool, true)
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
  }))
  default = {}
}

variable "origin_request_policies" {
  description = "Map of origin request policies to create (keyed by policy name for stable resource tracking)"
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