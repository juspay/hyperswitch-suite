output "policy_arns" {
  description = "Map of policy ARNs keyed by policy key"
  value = var.create ? {
    for key, policy in aws_iam_policy.this : key => policy.arn
  } : {}
}

output "policy_names" {
  description = "Map of policy names keyed by policy key"
  value = var.create ? {
    for key, policy in aws_iam_policy.this : key => policy.name
  } : {}
}