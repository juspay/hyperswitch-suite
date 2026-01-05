# =========================================================================
# SECURITY RULES OUTPUTS
# =========================================================================

output "locker_ingress_rule_ids" {
  description = "IDs of locker ingress security group rules"
  value       = { for k, v in aws_security_group_rule.locker_ingress : k => v.id }
}

output "locker_egress_rule_ids" {
  description = "IDs of locker egress security group rules"
  value       = { for k, v in aws_security_group_rule.locker_egress : k => v.id }
}

output "nlb_ingress_rule_ids" {
  description = "IDs of NLB ingress security group rules"
  value       = { for k, v in aws_security_group_rule.nlb_ingress : k => v.id }
}

output "nlb_egress_rule_ids" {
  description = "IDs of NLB egress security group rules"
  value       = { for k, v in aws_security_group_rule.nlb_egress : k => v.id }
}

output "rules_summary" {
  description = "Summary of security rules created"
  value = {
    locker_ingress_count = length(var.locker_ingress_rules)
    locker_egress_count  = length(var.locker_egress_rules)
    nlb_ingress_count    = length(var.nlb_ingress_rules)
    nlb_egress_count     = length(var.nlb_egress_rules)
    total_rules          = length(var.locker_ingress_rules) + length(var.locker_egress_rules) + length(var.nlb_ingress_rules) + length(var.nlb_egress_rules)
  }
}
