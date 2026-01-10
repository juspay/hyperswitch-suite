# =========================================================================
# SECURITY RULES OUTPUTS
# =========================================================================

# Group ingress rule IDs by security group
output "ingress_rule_ids" {
  description = "Map of ingress security group rule IDs grouped by security group ID"
  value = {
    for sg_id in distinct([for k, v in local.ingress_rules_flat : v.sg_id]) :
    sg_id => {
      for k, v in aws_security_group_rule.ingress :
      k => v.id if v.security_group_id == sg_id
    }
  }
}

# Group egress rule IDs by security group
output "egress_rule_ids" {
  description = "Map of egress security group rule IDs grouped by security group ID"
  value = {
    for sg_id in distinct([for k, v in local.egress_rules_flat : v.sg_id]) :
    sg_id => {
      for k, v in aws_security_group_rule.egress :
      k => v.id if v.security_group_id == sg_id
    }
  }
}

# Summary of all rules created
output "rules_summary" {
  description = "Summary of security rules created"
  value = {
    total_ingress_rules = length(local.ingress_rules_flat)
    total_egress_rules  = length(local.egress_rules_flat)
    total_rules         = length(local.ingress_rules_flat) + length(local.egress_rules_flat)

    ingress_by_sg = {
      for sg_id in distinct([for k, v in local.ingress_rules_flat : v.sg_id]) :
      sg_id => length([for k, v in local.ingress_rules_flat : k if v.sg_id == sg_id])
    }

    egress_by_sg = {
      for sg_id in distinct([for k, v in local.egress_rules_flat : v.sg_id]) :
      sg_id => length([for k, v in local.egress_rules_flat : k if v.sg_id == sg_id])
    }
  }
}
