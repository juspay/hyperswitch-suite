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

variable "cloudfront_functions" {
  type = map(object({
    name    = string
    runtime = optional(string, "cloudfront-js-1.0")
    comment = optional(string)
    code    = string
    publish = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
