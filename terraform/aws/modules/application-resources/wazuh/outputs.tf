output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "ID of the created IAM role"
  value       = aws_iam_role.this.id
}

# ==============================================================================
# S3 Bucket Outputs
# ==============================================================================

output "s3_bucket_name" {
  description = "Name of the created S3 bucket (null if not created)"
  value       = var.create_s3_bucket ? module.s3_bucket[0].s3_bucket_id : null
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket (null if not created)"
  value       = var.create_s3_bucket ? module.s3_bucket[0].s3_bucket_arn : null
}

output "s3_bucket_domain_name" {
  description = "Domain name of the created S3 bucket (null if not created)"
  value       = var.create_s3_bucket ? module.s3_bucket[0].s3_bucket_bucket_domain_name : null
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the created S3 bucket (null if not created)"
  value       = var.create_s3_bucket ? module.s3_bucket[0].s3_bucket_bucket_regional_domain_name : null
}

output "s3_bucket_region" {
  description = "AWS region of the created S3 bucket (null if not created)"
  value       = var.create_s3_bucket ? module.s3_bucket[0].s3_bucket_region : null
}

# ==============================================================================
# CloudWatch Logs Outputs
# ==============================================================================

output "cloudwatch_logs_policy_name" {
  description = "Name of the inline CloudWatch Logs policy attached to the role (null if not created)"
  value       = var.cloudwatch_logs_policy != null ? aws_iam_role_policy.cloudwatch_logs[0].name : null
}
