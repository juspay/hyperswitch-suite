variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where jump hosts will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for external jump host"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for internal jump host"
  type        = string
}

variable "external_jump_ami_id" {
  description = "AMI ID for external jump host (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

variable "internal_jump_ami_id" {
  description = "AMI ID for internal jump host (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type for jump hosts"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the root volume in GiB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# Security Group Rules Configuration
# =========================================================================

# External Jump Host - Ingress Rules
variable "external_jump_ingress_rules" {
  description = "Ingress rules for external jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))  # IPv4 CIDR blocks (e.g., ["13.232.74.226/32"])
    ipv6_cidr       = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string))  # Security Group IDs
    prefix_list_ids = optional(list(string))  # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.external_jump_ingress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

# External Jump Host - Egress Rules
variable "external_jump_egress_rules" {
  description = "Egress rules for external jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string))  # Security Group IDs
    prefix_list_ids = optional(list(string))  # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.external_jump_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

# Internal Jump Host - Egress Rules
variable "internal_jump_egress_rules" {
  description = "Egress rules for internal jump host security group. Use 'cidr' for IPv4, 'ipv6_cidr' for IPv6, 'sg_id' for security groups, or 'prefix_list_ids' for VPC endpoints"
  type = list(object({
    description     = string
    from_port       = number
    to_port         = number
    protocol        = string
    cidr            = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr       = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id           = optional(list(string))  # Security Group IDs
    prefix_list_ids = optional(list(string))  # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])
  }))
  default = []
  validation {
    condition = alltrue([
      for rule in var.internal_jump_egress_rules :
      # Must have exactly one of: cidr, ipv6_cidr, sg_id, or prefix_list_ids
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) + (rule.prefix_list_ids != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), 'sg_id' (Security Group), or 'prefix_list_ids' (VPC Endpoint)."
  }
}

variable "enable_internal_jump_ssm" {
  description = "Enable SSM Session Manager access for internal jump host. When true, adds SSM policies to internal jump IAM role"
  type        = bool
  default     = false
}