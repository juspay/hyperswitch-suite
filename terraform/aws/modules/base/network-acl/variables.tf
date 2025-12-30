variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "nacl_name" {
  description = "Name of the network ACL"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with this NACL"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    rule_number     = number
    protocol        = string
    rule_action     = string
    cidr_block      = optional(string)
    ipv6_cidr_block = optional(string)
    from_port       = optional(number)
    to_port         = optional(number)
    icmp_type       = optional(number)
    icmp_code       = optional(number)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    rule_number     = number
    protocol        = string
    rule_action     = string
    cidr_block      = optional(string)
    ipv6_cidr_block = optional(string)
    from_port       = optional(number)
    to_port         = optional(number)
    icmp_type       = optional(number)
    icmp_code       = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
