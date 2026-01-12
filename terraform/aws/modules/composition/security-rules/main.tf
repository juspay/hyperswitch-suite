# =========================================================================
# SECURITY RULES MODULE
# =========================================================================
# This module manages cross-module security group rules.
#
# Design Pattern:
#   - Security groups are created in their respective composition modules
#   - Cross-module connectivity rules are defined in the live layer
#   - Module-internal rules (e.g., NLB -> Instance) remain in composition modules
#
# Rule Placement Decision:
#   - Cross-module reference → security-rules module (this module)
#   - Same-module internal → stays in composition module
#
# Example:
#   - Jump host → Locker SSH: HERE (cross-module)
#   - Locker NLB → Locker instance: Locker module (same-module)
#
# New Architecture:
#   - Live layer defines rules organized by component
#   - Live layer merges rules into consolidated ingress/egress lists
#   - This module receives pre-grouped rules and creates them
# =========================================================================

# =========================================================================
# FLATTEN INGRESS RULES FOR ITERATION
# =========================================================================
locals {
  # Flatten the ingress rules structure for easier iteration
  # Creates a map with unique keys combining sg_id and rule hash
  ingress_rules_flat = merge([
    for group in var.ingress_rules : {
      for rule in group.rules :
      "${group.sg_id}_${sha256(jsonencode(rule))}" => {
        sg_id           = group.sg_id
        description     = rule.description
        from_port       = rule.from_port
        to_port         = rule.to_port
        protocol        = rule.protocol
        cidr            = rule.cidr
        ipv6_cidr       = rule.ipv6_cidr
        sg_id_source    = rule.sg_id
        prefix_list_ids = rule.prefix_list_ids
      }
    }
  ]...)

  # Flatten the egress rules structure for easier iteration
  egress_rules_flat = merge([
    for group in var.egress_rules : {
      for rule in group.rules :
      "${group.sg_id}_${sha256(jsonencode(rule))}" => {
        sg_id           = group.sg_id
        description     = rule.description
        from_port       = rule.from_port
        to_port         = rule.to_port
        protocol        = rule.protocol
        cidr            = rule.cidr
        ipv6_cidr       = rule.ipv6_cidr
        sg_id_source    = rule.sg_id
        prefix_list_ids = rule.prefix_list_ids
      }
    }
  ]...)
}

# =========================================================================
# INGRESS SECURITY GROUP RULES
# =========================================================================
resource "aws_security_group_rule" "ingress" {
  for_each = local.ingress_rules_flat

  security_group_id = each.value.sg_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id_source[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# EGRESS SECURITY GROUP RULES
# =========================================================================
resource "aws_security_group_rule" "egress" {
  for_each = local.egress_rules_flat

  security_group_id = each.value.sg_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id_source[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# END OF SECURITY RULES MODULE
# =========================================================================