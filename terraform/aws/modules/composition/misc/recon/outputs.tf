# =========================================================================
# IAM ROLE OUTPUTS
# =========================================================================
output "role_arn" {
  description = "ARN of the IAM role for recon service"
  value       = aws_iam_role.recon_role.arn
}

output "role_name" {
  description = "Name of the IAM role for recon service"
  value       = aws_iam_role.recon_role.name
}

# =========================================================================
# S3 BUCKET OUTPUTS
# =========================================================================
output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.recon_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.recon_bucket.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = module.recon_bucket.s3_bucket_bucket_domain_name
}

# =========================================================================
# IAM POLICY OUTPUTS
# =========================================================================
output "kms_policy_arn" {
  description = "ARN of the KMS IAM policy"
  value       = aws_iam_policy.recon_kms.arn
}

output "s3_policy_arn" {
  description = "ARN of the S3 IAM policy"
  value       = aws_iam_policy.recon_s3.arn
}
