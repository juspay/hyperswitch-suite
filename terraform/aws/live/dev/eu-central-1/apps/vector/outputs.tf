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

# ============================================================================
# S3 Bucket Outputs
# ============================================================================

output "s3_bucket_name" {
  description = "Name of the created S3 bucket (null if not created)"
  value       = module.eks_iam.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket (null if not created)"
  value       = module.eks_iam.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the created S3 bucket (null if not created)"
  value       = module.eks_iam.s3_bucket_domain_name
}
