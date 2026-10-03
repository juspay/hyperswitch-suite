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
  default     = "hyperswitch"
}

variable "managed_cache_policies" {
  description = "List of AWS managed cache policy names to look up"
  type        = list(string)
  default     = []
}

variable "managed_origin_request_policies" {
  description = "List of AWS managed origin request policy names to look up"
  type        = list(string)
  default     = []
}

variable "managed_response_headers_policies" {
  description = "List of AWS managed response headers policy names to look up"
  type        = list(string)
  default     = []
}

variable "custom_cache_policies" {
  description = "Map of custom cache policies to create"
  type = map(object({
    name        = string
    comment     = optional(string)
    default_ttl = optional(number)
    max_ttl     = optional(number)
    min_ttl     = optional(number)
    enable_accept_encoding_brotli = optional(bool, false)
    enable_accept_encoding_gzip   = optional(bool, true)
    headers_config_header_behavior = optional(string, "none")
    headers_config_headers         = optional(list(string), [])
    cookies_config_cookie_behavior = optional(string, "none")
    cookies_config_cookies         = optional(list(string), [])
    query_strings_config_query_string_behavior = optional(string, "none")
    query_strings_config_query_strings         = optional(list(string), [])
  }))
  default = {}
}

variable "custom_origin_request_policies" {
  description = "Map of custom origin request policies to create"
  type = map(object({
    name    = string
    comment = optional(string)
    headers_config_header_behavior = optional(string, "none")
    headers_config_headers         = optional(list(string), [])
    cookies_config_cookie_behavior = optional(string, "none")
    cookies_config_cookies         = optional(list(string), [])
    query_strings_config_query_string_behavior = optional(string, "none")
    query_strings_config_query_strings         = optional(list(string), [])
  }))
  default = {}
}

variable "custom_response_headers_policies" {
  description = "Map of custom response headers policies to create"
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
      origin_override                  = optional(bool, true)
    }))
    security_headers_config = optional(any)
    remove_headers_config = optional(object({
      items = list(string)
    }))
    custom_headers_config = optional(object({
      items = list(object({
        header   = string
        value    = string
        override = bool
      }))
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
