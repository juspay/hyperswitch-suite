variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "topics" {
  description = "Map of topic key -> config. Equivalent of AWS var.topics."
  type = map(object({
    name        = string
    description = optional(string)
    subscriptions = optional(map(object({
      protocol = string # EMAIL | HTTPS | PAGERDUTY | SLACK | SMS
      endpoint = string
    })), {})
  }))
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
