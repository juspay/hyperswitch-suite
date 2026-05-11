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
  description = "ARN of the IAM role for Decision Engine application"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role for Decision Engine application"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "ID of the IAM role for Decision Engine application"
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

output "inline_policies_enabled" {
  description = "Whether inline policies feature is enabled"
  value       = local.inline_policies_enabled
}

# =========================================================================
# S3 BUCKET OUTPUTS
# =========================================================================
output "s3_bucket_id" {
  description = "The ID (name) of the S3 bucket"
  value       = local.s3_bucket_create && length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_id : null
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = local.s3_bucket_create && length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_id : null
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = local.s3_bucket_create && length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_arn : null
}

output "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = local.s3_bucket_create && length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_bucket_domain_name : null
}

output "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = local.s3_bucket_create && length(module.s3_bucket) > 0 ? module.s3_bucket[0].s3_bucket_bucket_regional_domain_name : null
}
