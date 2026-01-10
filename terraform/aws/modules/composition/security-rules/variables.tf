# =========================================================================
# SECURITY RULES MODULE VARIABLES
# =========================================================================
# This module now accepts only ingress_rules and egress_rules.
# The live layer is responsible for:
#   1. Fetching security group IDs via terraform_remote_state
#   2. Defining rules organized by component (locker, squid, envoy, etc.)
#   3. Merging rules into consolidated ingress/egress lists
#   4. Passing merged lists to this module
# =========================================================================

variable "ingress_rules" {
  description = "List of ingress rules grouped by security group ID"
  type = list(object({
    sg_id = string
    rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr            = optional(list(string))    # IPv4 CIDR blocks
      ipv6_cidr       = optional(list(string))    # IPv6 CIDR blocks
      sg_id           = optional(list(string))    # Security Group IDs
      prefix_list_ids = optional(list(string))    # VPC Endpoint Prefix Lists
    }))
  }))
  default = []

  validation {
    condition = alltrue(flatten([
      for group in var.ingress_rules : [
        for rule in group.rules :
        # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
        (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "egress_rules" {
  description = "List of egress rules grouped by security group ID"
  type = list(object({
    sg_id = string
    rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr            = optional(list(string))    # IPv4 CIDR blocks
      ipv6_cidr       = optional(list(string))    # IPv6 CIDR blocks
      sg_id           = optional(list(string))    # Security Group IDs
      prefix_list_ids = optional(list(string))    # VPC Endpoint Prefix Lists
    }))
  }))
  default = []

  validation {
    condition = alltrue(flatten([
      for group in var.egress_rules : [
        for rule in group.rules :
        # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
        (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}