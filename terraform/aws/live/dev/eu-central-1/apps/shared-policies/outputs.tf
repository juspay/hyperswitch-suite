output "policy_arns" {
  description = "Map of policy ARNs keyed by policy key"
  value       = module.shared_policies.policy_arns
}

output "policy_names" {
  description = "Map of policy names keyed by policy key"
  value       = module.shared_policies.policy_names
}