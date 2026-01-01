# ============================================================================
# Security Rules Outputs
# ============================================================================

output "locker_ingress_rule_ids" {
  description = "IDs of locker ingress security group rules"
  value       = module.security_rules.locker_ingress_rule_ids
}

output "locker_egress_rule_ids" {
  description = "IDs of locker egress security group rules"
  value       = module.security_rules.locker_egress_rule_ids
}

output "nlb_ingress_rule_ids" {
  description = "IDs of NLB ingress security group rules"
  value       = module.security_rules.nlb_ingress_rule_ids
}

output "nlb_egress_rule_ids" {
  description = "IDs of NLB egress security group rules"
  value       = module.security_rules.nlb_egress_rule_ids
}

output "rules_summary" {
  description = "Summary of security rules created"
  value       = module.security_rules.rules_summary
}
