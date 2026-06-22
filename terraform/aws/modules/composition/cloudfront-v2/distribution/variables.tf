variable "create" {
  type    = bool
  default = true
}

variable "environment" {
  type = string
}

variable "project_name" {
  type    = string
  default = "hyperswitch"
}

variable "enabled" {
  type    = bool
  default = true
}

variable "is_ipv6_enabled" {
  type    = bool
  default = true
}

variable "comment" {
  type    = string
  default = ""
}

variable "price_class" {
  type    = string
  default = "PriceClass_All"
}

variable "http_version" {
  type    = string
  default = "http2"
}

variable "default_root_object" {
  type    = string
  default = ""
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "web_acl_id" {
  type    = string
  default = null
}

variable "staging" {
  type    = bool
  default = false
}

variable "continuous_deployment_policy_id" {
  type    = string
  default = null
}

variable "retain_on_delete" {
  type    = bool
  default = false
}

variable "origins" {
  type    = any
  default = {}
}

variable "origin_groups" {
  type    = any
  default = {}
}

variable "default_cache_behavior" {
  type    = any
  default = {}
}

variable "ordered_cache_behaviors" {
  type    = list(any)
  default = []
}

variable "custom_error_responses" {
  type    = list(any)
  default = []
}

variable "viewer_certificate" {
  type    = any
  default = {}
}

variable "geo_restriction" {
  type    = any
  default = { restriction_type = "none", locations = [] }
}

variable "logging_config" {
  type    = any
  default = {}
}

variable "origin_access_control" {
  type    = map(any)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
