output "rule_ids" {
  description = "Map of rule indices to their IDs"
  value       = var.create ? { for idx, rule in aws_security_group_rule.rules : idx => rule.id } : {}
}

output "rules_count" {
  description = "Number of security group rules created"
  value       = var.create ? length(aws_security_group_rule.rules) : 0
}
