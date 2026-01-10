# ============================================================================
# Security Rules Outputs
# ============================================================================

output "ingress_rule_ids" {
  description = "Map of ingress security group rule IDs grouped by security group ID"
  value       = module.security_rules.ingress_rule_ids
}

output "egress_rule_ids" {
  description = "Map of egress security group rule IDs grouped by security group ID"
  value       = module.security_rules.egress_rule_ids
}

output "rules_summary" {
  description = "Summary of security rules created"
  value       = module.security_rules.rules_summary
}
