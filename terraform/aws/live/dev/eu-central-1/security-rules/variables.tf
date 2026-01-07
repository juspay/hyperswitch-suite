# ============================================================================
# Security Rules Configuration Variables
# ============================================================================

variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
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
    cidr            = optional(list(string))
    ipv6_cidr       = optional(list(string))
    sg_id           = optional(list(string))
    prefix_list_ids = optional(list(string))
  }))
  default = []
}

variable "locker_egress_rules" {
  description = "Egress rules for locker security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
}

variable "nlb_ingress_rules" {
  description = "Ingress rules for NLB security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
}

variable "nlb_egress_rules" {
  description = "Egress rules for NLB security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
}

# =========================================================================
# SQUID PROXY SECURITY GROUP RULES
# =========================================================================

variable "squid_ingress_rules" {
  description = "Ingress rules for squid proxy security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
}

variable "squid_egress_rules" {
  description = "Egress rules for squid proxy security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
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
}

# =========================================================================
# ENVOY PROXY SECURITY GROUP RULES
# =========================================================================

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
}