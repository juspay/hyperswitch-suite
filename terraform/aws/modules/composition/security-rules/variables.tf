# =========================================================================
# SECURITY GROUP ID VARIABLES
# =========================================================================
# These variables accept security group IDs from other modules
# Passed from live layer via terraform_remote_state data sources
# =========================================================================

variable "locker_sg_id" {
  description = "Security group ID of the locker instance"
  type        = string
  default     = null
}

variable "locker_nlb_sg_id" {
  description = "Security group ID of the locker NLB"
  type        = string
  default     = null
}

variable "squid_sg_id" {
  description = "Security group ID of the squid instance"
  type        = string
  default     = null
}

variable "envoy_sg_id" {
  description = "Security group ID of the Envoy instance"
  type        = string
  default     = null
}

variable "envoy_lb_sg_id" {
  description = "Security group ID of the Envoy load balancer"
  type        = string
  default     = null
}

variable "ext_jump_host_sg_id" {
  description = "Security group ID of the jump host instance"
  type        = string
  default     = null
}

variable "int_jump_host_sg_id" {
  description = "Security group ID of the internal jump host instance"
  type        = string
  default     = null
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

# =========================================================================
# SQUID SECURITY GROUP RULES
# =========================================================================

variable "squid_ingress_rules" {
  description = "Ingress rules for squid security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
      for rule in var.squid_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
} 

variable "squid_egress_rules" {
  description = "Egress rules for squid security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
      for rule in var.squid_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

# ============================================================================
# ENVOY SECURITY GROUP RULES
# ============================================================================
variable "envoy_ingress_rules" {
  description = "Ingress rules for Envoy security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) 
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.envoy_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}
variable "envoy_egress_rules" {
  description = "Egress rules for Envoy security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string)) 
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.envoy_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "envoy_lb_ingress_rules" {
  description = "Ingress rules for Envoy load balancer security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.envoy_lb_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "envoy_lb_egress_rules" {
  description = "Egress rules for Envoy load balancer security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.envoy_lb_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

# =========================================================================
# JUMP HOST SECURITY GROUP RULES
# =========================================================================
variable "ext_jump_host_ingress_rules" {
  description = "Ingress rules for external jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.ext_jump_host_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "ext_jump_host_egress_rules" {
  description = "Egress rules for external jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.ext_jump_host_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "int_jump_host_ingress_rules" {
  description = "Ingress rules for internal jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.int_jump_host_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "int_jump_host_egress_rules" {
  description = "Egress rules for internal jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.int_jump_host_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}
