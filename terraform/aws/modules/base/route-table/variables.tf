variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "route_table_name" {
  description = "Name of the route table"
  type        = string
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

variable "create_vpc_peering_route" {
  description = "Whether to create a route to a VPC peering connection"
  type        = bool
  default     = false
}

variable "vpc_peering_destination_cidr" {
  description = "Destination CIDR block for VPC peering route"
  type        = string
  default     = ""
}

variable "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
