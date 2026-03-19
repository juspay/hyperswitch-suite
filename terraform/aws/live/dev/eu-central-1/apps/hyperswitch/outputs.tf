# ============================================================================
# Hyperswitch Application Resources Outputs
# ============================================================================

# General Outputs
output "hyperswitch_region" {
  description = "AWS region where resources are created"
  value       = module.hyperswitch.region
}

output "hyperswitch_account_id" {
  description = "AWS account ID"
  value       = module.hyperswitch.account_id
}

# IAM Role Outputs
output "hyperswitch_role_arn" {
  description = "ARN of the IAM role for Hyperswitch application"
  value       = module.hyperswitch.role_arn
}

output "hyperswitch_role_name" {
  description = "Name of the IAM role for Hyperswitch application"
  value       = module.hyperswitch.role_name
}

# KMS Key Outputs
output "hyperswitch_kms_key_enabled" {
  description = "Whether KMS key feature is enabled"
  value       = module.hyperswitch.kms_key_enabled
}

output "hyperswitch_kms_key_arn" {
  description = "ARN of the KMS key (created or existing)"
  value       = module.hyperswitch.kms_key_arn
}

# S3 Dashboard Themes Outputs
output "hyperswitch_s3_dashboard_themes_enabled" {
  description = "Whether S3 dashboard themes feature is enabled"
  value       = module.hyperswitch.s3_dashboard_themes_enabled
}

output "hyperswitch_s3_dashboard_themes_bucket_arn" {
  description = "ARN of the dashboard themes S3 bucket"
  value       = module.hyperswitch.s3_dashboard_themes_bucket_arn
}

output "hyperswitch_s3_dashboard_themes_bucket_name" {
  description = "Name of the dashboard themes S3 bucket"
  value       = module.hyperswitch.s3_dashboard_themes_bucket_name
}

# S3 File Uploads Outputs
output "hyperswitch_s3_file_uploads_enabled" {
  description = "Whether S3 file uploads feature is enabled"
  value       = module.hyperswitch.s3_file_uploads_enabled
}

output "hyperswitch_s3_file_uploads_bucket_arn" {
  description = "ARN of the file uploads S3 bucket"
  value       = module.hyperswitch.s3_file_uploads_bucket_arn
}

output "hyperswitch_s3_file_uploads_bucket_name" {
  description = "Name of the file uploads S3 bucket"
  value       = module.hyperswitch.s3_file_uploads_bucket_name
}

# SES Outputs
output "hyperswitch_ses_enabled" {
  description = "Whether SES feature is enabled"
  value       = module.hyperswitch.ses_enabled
}

# Secrets Manager Outputs
output "hyperswitch_secrets_manager_enabled" {
  description = "Whether Secrets Manager feature is enabled"
  value       = module.hyperswitch.secrets_manager_enabled
}

# Assume Role Outputs
output "hyperswitch_assume_role_enabled" {
  description = "Whether cross-account assume role feature is enabled"
  value       = module.hyperswitch.assume_role_enabled
}

# Lambda Outputs
output "hyperswitch_lambda_enabled" {
  description = "Whether Lambda feature is enabled"
  value       = module.hyperswitch.lambda_enabled
}
