variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "zones" {
  description = "Map of zone key -> config. Equivalent of the AWS module's var.route53_zones."
  type = map(object({
    name      = string
    zone_type = optional(string, "PRIMARY") # PRIMARY (public) | SECONDARY
    scope     = optional(string, "GLOBAL")  # GLOBAL (public) | PRIVATE
    vcn_id    = optional(string)            # required when scope = PRIVATE
    records = optional(map(object({
      rtype = string
      rdata = list(string)
      ttl   = optional(number, 300)
    })), {})
    tags = optional(map(string), {})
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
