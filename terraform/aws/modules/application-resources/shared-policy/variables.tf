variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    name        = string
    description = string
    path        = string
    policy      = string
    tags        = optional(map(string), {})
  }))
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}