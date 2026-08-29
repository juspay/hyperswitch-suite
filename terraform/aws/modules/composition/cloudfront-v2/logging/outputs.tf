output "bucket_id" {
  description = "S3 bucket name"
  value       = var.create ? aws_s3_bucket.logs[0].id : null
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = var.create ? aws_s3_bucket.logs[0].arn : null
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = var.create ? aws_s3_bucket.logs[0].bucket_domain_name : null
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = var.create ? aws_s3_bucket.logs[0].bucket_regional_domain_name : null
}
