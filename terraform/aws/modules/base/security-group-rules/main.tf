# ============================================================================
# Flexible Security Group Rules Module
# ============================================================================
# This module creates security group rules with support for:
# - cidr: list(string) for IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])
# - ipv6_cidr: list(string) for IPv6 CIDR blocks (e.g., ["::/0"])
# - sg_id: list(string) for Security Group IDs
#
# The type field determines if it's ingress or egress
# ============================================================================

resource "aws_security_group_rule" "rules" {
  for_each = { for idx, rule in var.rules : idx => rule }

  security_group_id = var.security_group_id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  # IPv4 CIDR blocks
  cidr_blocks = try(each.value.cidr, null)

  # IPv6 CIDR blocks
  ipv6_cidr_blocks = try(each.value.ipv6_cidr, null)

  # Security Group ID (take first element since it's a list)
  source_security_group_id = try(each.value.sg_id[0], null)
}
