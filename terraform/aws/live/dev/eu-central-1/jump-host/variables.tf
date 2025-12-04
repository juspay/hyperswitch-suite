# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

# ============================================================================
# Network Configuration
# ============================================================================
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

# ============================================================================
# Instance Configuration
# ============================================================================
variable "external_jump_ami_id" {
  description = "AMI ID for external jump host (defaults to latest Amazon Linux 2 if not provided)"
  type        = string
  default     = null
}

variable "internal_jump_ami_id" {
  description = "AMI ID for internal jump host (defaults to latest Amazon Linux 2 if not provided)"
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

# ============================================================================
# Logging Configuration
# ============================================================================
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# ============================================================================
# Migration Mode Configuration
# ============================================================================
variable "enable_migration_mode" {
  description = "Enable SSM SendCommand permissions for Packer migration. Should be disabled after migration is complete for security. Only affects: ssm:DescribeInstanceInformation, ssm:SendCommand, ssm:GetCommandInvocation, ssm:ListCommandInvocations"
  type        = bool
  default     = false
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Security Group Rules Configuration
# ============================================================================

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
}

# ============================================================================
# SSM Session Manager Configuration
# ============================================================================
variable "enable_internal_jump_ssm" {
  description = "Enable SSM Session Manager access for internal jump host. When true, SSM policies will be dynamically attached to the internal jump IAM role"
  type        = bool
  default     = false
}
