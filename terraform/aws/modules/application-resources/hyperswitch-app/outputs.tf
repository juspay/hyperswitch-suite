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
  description = "ARN of the IAM role for Hyperswitch application"
  value       = aws_iam_role.iam_role.arn
}

output "role_name" {
  description = "Name of the IAM role for Hyperswitch application"
  value       = aws_iam_role.iam_role.name
}

# =========================================================================
# KMS KEY OUTPUTS
# =========================================================================
output "kms_key_enabled" {
  description = "Whether KMS key feature is enabled"
  value       = local.kms_enabled
}

output "kms_key_arn" {
  description = "ARN of the KMS key (created or existing)"
  value       = local.kms_enabled ? local.kms_key_arn : null
}

output "kms_key_id" {
  description = "ID of the created KMS key (only if created by this module)"
  value       = local.kms_create && length(module.kms) > 0 ? module.kms[0].key_id : null
}

output "kms_key_aliases" {
  description = "Map of aliases created for the KMS key (only if created by this module)"
  value       = local.kms_create && length(module.kms) > 0 ? module.kms[0].aliases : {}
}

output "kms_policy_arn" {
  description = "ARN of the KMS IAM policy (if enabled)"
  value       = local.kms_enabled ? aws_iam_policy.kms_policy[0].arn : null
}

# =========================================================================
# S3 BUCKET OUTPUTS - Dashboard Themes
# =========================================================================
output "s3_dashboard_themes_enabled" {
  description = "Whether S3 dashboard themes feature is enabled"
  value       = local.s3_dashboard_themes_enabled
}

output "s3_dashboard_themes_bucket_arn" {
  description = "ARN of the dashboard themes S3 bucket (created or existing)"
  value       = local.s3_dashboard_themes_enabled ? local.s3_dashboard_themes_bucket_arn : null
}

output "s3_dashboard_themes_bucket_name" {
  description = "Name of the dashboard themes S3 bucket (only if created by this module)"
  value       = local.s3_dashboard_themes_create && length(module.s3_dashboard_themes) > 0 ? module.s3_dashboard_themes.s3_bucket_id : null
}

output "s3_dashboard_themes_policy_arn" {
  description = "ARN of the dashboard themes S3 IAM policy (if enabled)"
  value       = local.s3_dashboard_themes_enabled ? aws_iam_policy.s3_dashboard_themes_policy[0].arn : null
}

# =========================================================================
# S3 BUCKET OUTPUTS - File Uploads
# =========================================================================
output "s3_file_uploads_enabled" {
  description = "Whether S3 file uploads feature is enabled"
  value       = local.s3_file_uploads_enabled
}

output "s3_file_uploads_bucket_arn" {
  description = "ARN of the file uploads S3 bucket (created or existing)"
  value       = local.s3_file_uploads_enabled ? local.s3_file_uploads_bucket_arn : null
}

output "s3_file_uploads_bucket_name" {
  description = "Name of the file uploads S3 bucket (only if created by this module)"
  value       = local.s3_file_uploads_create && length(module.s3_file_uploads) > 0 ? module.s3_file_uploads.s3_bucket_id : null
}

output "s3_file_uploads_policy_arn" {
  description = "ARN of the file uploads S3 IAM policy (if enabled)"
  value       = local.s3_file_uploads_enabled ? aws_iam_policy.s3_file_uploads_policy[0].arn : null
}

# =========================================================================
# SES OUTPUTS
# =========================================================================
output "ses_enabled" {
  description = "Whether SES feature is enabled"
  value       = local.ses_enabled
}

output "ses_role_arn" {
  description = "ARN of the SES role being assumed (if configured)"
  value       = local.ses_role_arn
}

output "ses_policy_arn" {
  description = "ARN of the SES IAM policy (if enabled)"
  value       = local.ses_enabled ? aws_iam_policy.ses_policy[0].arn : null
}

# =========================================================================
# SECRETS MANAGER OUTPUTS
# =========================================================================
output "secrets_manager_enabled" {
  description = "Whether Secrets Manager feature is enabled"
  value       = local.secrets_manager_enabled
}

output "secrets_manager_policy_arn" {
  description = "ARN of the Secrets Manager IAM policy (if enabled)"
  value       = local.secrets_manager_enabled ? aws_iam_policy.secrets_manager_policy[0].arn : null
}

# =========================================================================
# ASSUME ROLE OUTPUTS
# =========================================================================
output "assume_role_enabled" {
  description = "Whether cross-account assume role feature is enabled"
  value       = local.assume_role_enabled
}

output "assume_role_policy_arn" {
  description = "ARN of the assume role IAM policy (if enabled)"
  value       = local.assume_role_enabled ? aws_iam_policy.assume_role_policy[0].arn : null
}

# =========================================================================
# LAMBDA OUTPUTS
# =========================================================================
output "lambda_enabled" {
  description = "Whether Lambda feature is enabled"
  value       = local.lambda_enabled
}

output "lambda_policy_arn" {
  description = "ARN of the Lambda IAM policy (if enabled)"
  value       = local.lambda_enabled ? aws_iam_policy.lambda_policy[0].arn : null
}

output "lambda_function_arns" {
  description = "List of Lambda function ARNs configured for access"
  value       = local.lambda_function_arns
}
