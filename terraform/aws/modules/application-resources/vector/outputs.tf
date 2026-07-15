# =========================================================================
# GENERAL OUTPUTS
# =========================================================================
output "region" {
  description = "AWS region where resources are created"
  value       = data.aws_region.current.id
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# =========================================================================
# IAM ROLE OUTPUTS
# =========================================================================
output "role_arn" {
  description = "ARN of the IAM role for Vector application"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role for Vector application"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role for Vector application"
  value       = aws_iam_role.this.id
}

# =========================================================================
# FEATURE ENABLEMENT OUTPUTS
# =========================================================================
output "oidc_enabled" {
  description = "Whether OIDC/IRSA feature is enabled"
  value       = local.oidc_enabled
}

output "assume_role_principals_enabled" {
  description = "Whether assume role principals feature is enabled"
  value       = local.assume_role_principals_enabled
}

output "aws_managed_policies_enabled" {
  description = "Whether AWS managed policy attachments feature is enabled"
  value       = local.aws_managed_policies_enabled
}

output "customer_managed_policies_enabled" {
  description = "Whether customer managed policy attachments feature is enabled"
  value       = local.customer_managed_policies_enabled
}

output "s3_enabled" {
  description = "Whether S3 bucket feature is enabled"
  value       = local.s3_enabled
}

# =========================================================================
# S3 BUCKET OUTPUTS
# =========================================================================
output "s3_bucket_name" {
  description = "Name of the S3 bucket (null if not created)"
  value       = local.s3_create ? module.s3_bucket[0].s3_bucket_id : null
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket (null if not enabled)"
  value       = local.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket (null if not created)"
  value       = local.s3_create ? module.s3_bucket[0].s3_bucket_bucket_domain_name : null
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (null if not created)"
  value       = local.s3_create ? module.s3_bucket[0].s3_bucket_bucket_regional_domain_name : null
}

output "s3_bucket_region" {
  description = "AWS region of the S3 bucket (null if not created)"
  value       = local.s3_create ? module.s3_bucket[0].s3_bucket_region : null
}

output "s3_policy_arn" {
  description = "ARN of the S3 IAM policy (if enabled)"
  value       = local.s3_enabled ? aws_iam_policy.s3_policy[0].arn : null
}

# =========================================================================
# SQS QUEUE OUTPUTS
# =========================================================================
output "sqs_enabled" {
  description = "Whether SQS queue feature is enabled"
  value       = local.sqs_enabled
}

output "sqs_queue_url" {
  description = "URL of the SQS queue (null if not created)"
  value       = local.sqs_enabled ? aws_sqs_queue.this[0].url : null
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue (null if not created)"
  value       = local.sqs_enabled ? aws_sqs_queue.this[0].arn : null
}

output "sqs_queue_name" {
  description = "Name of the SQS queue (null if not created)"
  value       = local.sqs_enabled ? aws_sqs_queue.this[0].name : null
}

output "sqs_policy_arn" {
  description = "ARN of the SQS IAM policy (if enabled)"
  value       = local.sqs_enabled ? aws_iam_policy.sqs_policy[0].arn : null
}

output "sqs_cross_region_enabled" {
  description = "Whether cross-region SQS read feature is enabled"
  value       = local.sqs_cross_region_enabled
}

output "sqs_cross_region_policy_arn" {
  description = "ARN of the cross-region SQS IAM policy (if enabled)"
  value       = local.sqs_cross_region_enabled ? aws_iam_policy.sqs_cross_region_policy[0].arn : null
}
