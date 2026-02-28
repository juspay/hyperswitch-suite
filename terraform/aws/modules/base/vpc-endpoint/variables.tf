variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "endpoint_name" {
  description = "Name of the VPC endpoint"
  type        = string
}

variable "service_name" {
  description = "The service name for the VPC endpoint"
  type        = string
}

variable "vpc_endpoint_type" {
  description = "The VPC endpoint type (Gateway, Interface, or GatewayLoadBalancer)"
  type        = string
  default     = "Interface"
  validation {
    condition     = contains(["Gateway", "Interface", "GatewayLoadBalancer"], var.vpc_endpoint_type)
    error_message = "VPC endpoint type must be Gateway, Interface, or GatewayLoadBalancer."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for Interface/GatewayLoadBalancer endpoints"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for Gateway endpoints"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for Interface endpoints"
  type        = list(string)
  default     = []
}

variable "private_dns_enabled" {
  description = "Whether to associate a private hosted zone with the VPC (Interface endpoints only)"
  type        = bool
  default     = true
}

variable "dns_record_ip_type" {
  description = "The DNS records IP type for the endpoint. Valid values: ipv4, dualstack, ipv6"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack", "ipv6"], var.dns_record_ip_type)
    error_message = "DNS record IP type must be ipv4, dualstack, or ipv6."
  }
}

variable "ip_address_type" {
  description = "The IP address type for the endpoint. Valid values: ipv4, dualstack, ipv6"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack", "ipv6"], var.ip_address_type)
    error_message = "IP address type must be ipv4, dualstack, or ipv6."
  }
}

variable "policy" {
  description = "A policy to attach to the endpoint. Defaults to full access"
  type        = string
  default     = null
}

variable "auto_accept" {
  description = "Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account)"
  type        = bool
  default     = null
}

variable "create_timeout" {
  description = "Timeout for creating the VPC endpoint"
  type        = string
  default     = "10m"
}

variable "update_timeout" {
  description = "Timeout for updating the VPC endpoint"
  type        = string
  default     = "10m"
}

variable "delete_timeout" {
  description = "Timeout for deleting the VPC endpoint"
  type        = string
  default     = "10m"
}

variable "create_security_group" {
  description = "Whether to create a security group for the endpoint"
  type        = bool
  default     = false
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC (used for security group rules)"
  type        = string
  default     = ""
}

variable "custom_ingress_rules" {
  description = "Map of custom ingress rules for the endpoint security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
    description = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
