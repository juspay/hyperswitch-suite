variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "ami_id" {
  description = "Custom AMI ID for locker instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1"
  }
}

variable "locker_port" {
  description = "Port number for the locker service"
  type        = number
  default     = 8080
}

variable "key_name" {
  description = "SSH key pair name. Required if create_key_pair is false. If create_key_pair is true and this is provided, it will be used as the name for the new key pair; otherwise an auto-generated name will be used"
  type        = string
  default     = null
  validation {
    condition     = var.create_key_pair || var.key_name != null
    error_message = "key_name must be provided when create_key_pair is false"
  }
}

variable "create_key_pair" {
  description = "Whether to create a new SSH key pair. If true, public_key must be provided"
  type        = bool
  default     = false
}

variable "public_key" {
  description = "Public key material for creating new SSH key pair. Optional - if not provided when create_key_pair is true, a new key pair will be auto-generated and the private key will be stored in SSM Parameter Store"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "locker_subnet_id" {
  description = "Subnet ID for the locker instance. Required if create_subnet is false"
  type        = string
  default     = null
  validation {
    condition     = var.create_subnet || var.locker_subnet_id != null
    error_message = "locker_subnet_id must be provided when create_subnet is false"
  }
}

variable "create_subnet" {
  description = "Whether to create a new subnet for the locker instance. If true, subnet_cidr_block must be provided"
  type        = bool
  default     = false
}

variable "subnet_cidr_block" {
  description = "CIDR block for the new subnet. Required if create_subnet is true"
  type        = string
  default     = null
  validation {
    condition     = var.create_subnet ? var.subnet_cidr_block != null : true
    error_message = "subnet_cidr_block must be provided when create_subnet is true"
  }
}

variable "subnet_availability_zone" {
  description = "Availability zone for the new subnet. If not provided, will use the first available AZ in the region"
  type        = string
  default     = null
}

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

variable "nlb_listeners" {
  description = "NLB listener configurations for the Network Load Balancer"
  type = map(object({
    port              = number
    protocol          = string
    target_group_arn  = optional(string) # If not provided, will use the default locker target group
    certificate_arn   = optional(string) # Required for TLS/HTTPS protocol
  }))
  default = {
    "http" = {
      port     = 80
      protocol = "TCP"
    }
  }
  validation {
    condition = alltrue([
      for key, listener in var.nlb_listeners :
      contains(["TCP", "UDP", "TCP_UDP", "TLS", "HTTP", "HTTPS"], listener.protocol)
    ])
    error_message = "Listener protocol must be one of: TCP, UDP, TCP_UDP, TLS, HTTP, HTTPS"
  }
}
