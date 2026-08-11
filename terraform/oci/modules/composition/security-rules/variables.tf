# ============================================================================
# Cross-module NSG rules - equivalent of the AWS `security-rules` composition
# module. Same design pattern: NSGs are created in their own composition
# modules; cross-module connectivity rules live here, defined at the live
# layer, grouped by NSG.
# ============================================================================

variable "ingress_rules" {
  description = <<-EOT
    Map of group name -> { nsg_id, rules[] }. Equivalent of AWS var.ingress_rules
    (group.sg_id -> group.nsg_id).
  EOT
  type = map(object({
    nsg_id = string
    rules = list(object({
      description   = optional(string, "")
      protocol      = optional(string, "6") # OCI protocol number: 6=TCP, 17=UDP, 1=ICMP, "all"
      port_min      = optional(number)
      port_max      = optional(number)
      cidr          = optional(string) # source_type = CIDR_BLOCK
      source_nsg_id = optional(string) # source_type = NETWORK_SECURITY_GROUP
    }))
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of group name -> { nsg_id, rules[] }. Equivalent of AWS var.egress_rules."
  type = map(object({
    nsg_id = string
    rules = list(object({
      description        = optional(string, "")
      protocol           = optional(string, "6")
      port_min           = optional(number)
      port_max           = optional(number)
      cidr               = optional(string)
      destination_nsg_id = optional(string)
    }))
  }))
  default = {}
}
