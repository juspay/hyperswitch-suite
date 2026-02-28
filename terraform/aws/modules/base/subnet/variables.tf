variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "cidr_block" {
  description = "The IPv4 CIDR block for the subnet"
  type        = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Subnet CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone" {
  description = "The AZ for the subnet"
  type        = string
}

variable "subnet_tier" {
  description = "Tier of the subnet (e.g., public, private, database, cache)"
  type        = string
  default     = ""
}

variable "subnet_type" {
  description = "Type of the subnet (e.g., public, private-nat, private-isolated)"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private-nat", "private-isolated"], var.subnet_type)
    error_message = "Subnet type must be public, private-nat, or private-isolated."
  }
}

variable "ipv6_cidr_block" {
  description = "The IPv6 CIDR block for the subnet"
  type        = string
  default     = null
}

variable "assign_ipv6_address_on_creation" {
  description = "Specify true to indicate that network interfaces created in the subnet should be assigned an IPv6 address"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
  type        = bool
  default     = false
}

variable "customer_owned_ipv4_pool" {
  description = "The customer owned IPv4 address pool"
  type        = string
  default     = null
}

variable "map_customer_owned_ip_on_launch" {
  description = "Specify true to indicate that network interfaces created in the subnet should be assigned a customer owned IP address"
  type        = bool
  default     = null
}

variable "outpost_arn" {
  description = "The ARN of the Outpost"
  type        = string
  default     = null
}

variable "enable_dns64" {
  description = "Indicates whether DNS queries made to the Amazon-provided DNS Resolver return synthetic IPv6 addresses for IPv4-only destinations"
  type        = bool
  default     = false
}

variable "enable_resource_name_dns_a_record_on_launch" {
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records"
  type        = bool
  default     = false
}

variable "enable_resource_name_dns_aaaa_record_on_launch" {
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records"
  type        = bool
  default     = false
}

variable "private_dns_hostname_type_on_launch" {
  description = "The type of hostnames to assign to instances in the subnet at launch"
  type        = string
  default     = null
  validation {
    condition     = var.private_dns_hostname_type_on_launch == null || contains(["ip-name", "resource-name"], var.private_dns_hostname_type_on_launch)
    error_message = "Private DNS hostname type must be ip-name or resource-name."
  }
}

variable "create_route_table" {
  description = "Whether to create a route table for this subnet"
  type        = bool
  default     = true
}

variable "route_table_id" {
  description = "ID of existing route table to associate with subnet (only used if create_route_table is false)"
  type        = string
  default     = ""
}

variable "create_internet_gateway_route" {
  description = "Whether to create a route to the internet gateway"
  type        = bool
  default     = false
}

variable "internet_gateway_id" {
  description = "ID of the internet gateway"
  type        = string
  default     = ""
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway in this subnet"
  type        = bool
  default     = false
}

variable "nat_gateway_eip_allocation_id" {
  description = "Allocation ID of EIP for NAT gateway"
  type        = string
  default     = ""
}

variable "nat_gateway_connectivity_type" {
  description = "Connectivity type for the NAT gateway. Valid values: private, public"
  type        = string
  default     = "public"
  validation {
    condition     = contains(["private", "public"], var.nat_gateway_connectivity_type)
    error_message = "NAT gateway connectivity type must be private or public."
  }
}

variable "create_nat_gateway_route" {
  description = "Whether to create a route to a NAT gateway"
  type        = bool
  default     = false
}

variable "nat_gateway_id" {
  description = "ID of the NAT gateway to route traffic through"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
