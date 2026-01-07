# =========================================================================
# SECURITY RULES MODULE
# =========================================================================
# This module manages cross-module security group rules.
#
# Design Pattern:
#   - Security groups are created in their respective composition modules
#   - Cross-module connectivity rules are defined here
#   - Module-internal rules (e.g., NLB -> Instance) remain in composition modules
#
# Rule Placement Decision:
#   - Cross-module reference → security-rules module (this module)
#   - Same-module internal → stays in composition module
#
# Example:
#   - Jump host → Locker SSH: HERE (cross-module)
#   - Locker NLB → Locker instance: Locker module (same-module)
# =========================================================================

# =========================================================================
# LOCKER SECURITY GROUP - INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "locker_ingress" {
  for_each = var.locker_sg_id != null ? { for rule in var.locker_ingress_rules : sha256(jsonencode(rule)) => rule } : {}

  security_group_id = var.locker_sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# LOCKER SECURITY GROUP - EGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "locker_egress" {
  for_each = var.locker_sg_id != null ? { for rule in var.locker_egress_rules : sha256(jsonencode(rule)) => rule } : {}

  security_group_id = var.locker_sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# NLB SECURITY GROUP - INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "nlb_ingress" {
  for_each = var.locker_nlb_sg_id != null ? { for rule in var.nlb_ingress_rules : sha256(jsonencode(rule)) => rule } : {}

  security_group_id = var.locker_nlb_sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# NLB SECURITY GROUP - EGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "nlb_egress" {
  for_each = var.locker_nlb_sg_id != null ? { for rule in var.nlb_egress_rules : sha256(jsonencode(rule)) => rule } : {}

  security_group_id = var.locker_nlb_sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# SQUID SECURITY GROUP - INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "squid_ingress" {
  for_each = var.squid_sg_id != null ? { for rule in var.squid_ingress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.squid_sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# SQUID SECURITY GROUP - EGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "squid_egress" {
  for_each = var.squid_sg_id != null ? { for rule in var.squid_egress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.squid_sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# ENVOY SECURITY GROUP - INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "envoy_ingress" {
  for_each = var.envoy_sg_id != null ? { for rule in var.envoy_ingress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.envoy_sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# ENVOY SECURITY GROUP - EGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "envoy_egress" {
  for_each = var.envoy_sg_id != null ? { for rule in var.envoy_egress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.envoy_sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# ENVOY LB SECURITY GROUP - INGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "envoy_lb_ingress" {
  for_each = var.envoy_lb_sg_id != null ? { for rule in var.envoy_lb_ingress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.envoy_lb_sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)    
}

# =========================================================================
# ENVOY LB SECURITY GROUP - EGRESS RULES
# =========================================================================
resource "aws_security_group_rule" "envoy_lb_egress" {
  for_each = var.envoy_lb_sg_id != null ? { for rule in var.envoy_lb_egress_rules : sha256(jsonencode(rule)) => rule } : {}
  security_group_id = var.envoy_lb_sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# END OF SECURITY RULES MODULE
# =========================================================================

