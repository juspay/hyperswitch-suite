# =========================================================================
# SECURITY GROUP ID VARIABLES
# =========================================================================
# These variables accept security group IDs from other modules
# Passed from live layer via terraform_remote_state data sources
# =========================================================================

variable "locker_sg_id" {
  description = "Security group ID of the locker instance"
  type        = string
}

variable "locker_nlb_sg_id" {
  description = "Security group ID of the locker NLB"
  type        = string
}

# =========================================================================
# LOCKER SECURITY GROUP RULES
# =========================================================================

variable "locker_ingress_rules" {
  description = "Ingress rules for locker security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string)) # Security Group IDs
    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.locker_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "locker_egress_rules" {
  description = "Egress rules for locker security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string)) # Security Group IDs
    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.locker_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "nlb_ingress_rules" {
  description = "Ingress rules for NLB security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string)) # Security Group IDs
    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.nlb_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "nlb_egress_rules" {
  description = "Egress rules for NLB security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string)) # Security Group IDs
    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.nlb_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}
