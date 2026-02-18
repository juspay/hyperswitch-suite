output "role_name" {
  description = "Name of the created IAM role"
  value       = module.eks_iam.role_name
}

output "role_arn" {
  description = "ARN of the created IAM role"
  value       = module.eks_iam.role_arn
}

output "role_id" {
  description = "ID of the created IAM role"
  value       = module.eks_iam.role_id
}
