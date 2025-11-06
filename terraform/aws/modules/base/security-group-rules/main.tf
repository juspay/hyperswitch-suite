# ============================================================================
# Flexible Security Group Rules Module
# ============================================================================
# This module creates security group rules with separate fields for:
# - cidr: list(string) for CIDR blocks
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

  # Use cidr field if provided
  cidr_blocks = try(each.value.cidr, null)

  # Use sg_id field if provided (take first element since it's a list)
  source_security_group_id = try(each.value.sg_id[0], null)
}
