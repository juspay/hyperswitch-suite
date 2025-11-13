variable "security_group_id" {
  description = "The security group ID to attach the rules to"
  type        = string
}

variable "rules" {
  description = "Security group rules. Can specify IPv4 CIDR, IPv6 CIDR, or Security Group ID"
  type = list(object({
    type        = string                  # "ingress" or "egress"
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = optional(list(string))  # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
    ipv6_cidr   = optional(list(string))  # IPv6 CIDR blocks (e.g., ["::/0"])
    sg_id       = optional(list(string))  # Security Group IDs
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rules :
      # Must have exactly one of: cidr, ipv6_cidr, or sg_id
      (rule.cidr != null ? 1 : 0) + (rule.ipv6_cidr != null ? 1 : 0) + (rule.sg_id != null ? 1 : 0) == 1
    ])
    error_message = "Each rule must have exactly one of 'cidr' (IPv4), 'ipv6_cidr' (IPv6), or 'sg_id' (Security Group)."
  }
}
