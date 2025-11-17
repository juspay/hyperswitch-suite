variable "security_group_id" {
  description = "The security group ID to attach the rules to"
  type        = string
}

variable "rules" {
  description = "Security group rules. The 'source' field can be either CIDR blocks (list) or Security Group ID (string)"
  type = list(object({
    type        = string # "ingress" or "egress"
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr      = optional (list(string))    # Can be list(string) for CIDRs OR string for SG ID
    sg_id     = optional (list(string))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rules :
      (rule.cidr != null && rule.sg_id == null) || (rule.cidr == null && rule.sg_id != null)
    ])
    error_message = "Each rule must have either 'cidr' or 'sg_id', but not both."
  }
}