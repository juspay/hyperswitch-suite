output "policies" {
  description = "Map of created IAM policies with names and ARNs"
  value = {
    for key, policy in aws_iam_policy.this : key => {
      name = policy.name
      arn  = policy.arn
    }
  }
}

output "policy_names" {
  description = "List of all created policy names"
  value       = values(aws_iam_policy.this)[*].name
}

output "policy_arns" {
  description = "List of all created policy ARNs"
  value       = values(aws_iam_policy.this)[*].arn
}

output "roles" {
  description = "Map of created IAM roles with names and ARNs"
  value = {
    for key, role in aws_iam_role.this : key => {
      name = role.name
      arn  = role.arn
    }
  }
}

output "role_names" {
  description = "List of all created role names"
  value       = values(aws_iam_role.this)[*].name
}

output "role_arns" {
  description = "List of all created role ARNs"
  value       = values(aws_iam_role.this)[*].arn
}