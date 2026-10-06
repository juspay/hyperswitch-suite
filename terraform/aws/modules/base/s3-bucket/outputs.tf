output "bucket_id" {
  description = "The ID (name) of the bucket"
  value       = local.bucket_id
}

output "bucket_name" {
  description = "The name of the bucket (alias for bucket_id)"
  value       = local.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = local.bucket_arn
}

output "bucket_domain_name" {
  description = "The bucket domain name (null when create_bucket = false)"
  value       = one(aws_s3_bucket.this[*].bucket_domain_name)
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name (null when create_bucket = false)"
  value       = one(aws_s3_bucket.this[*].bucket_regional_domain_name)
}

output "bucket_region" {
  description = "The AWS region of the bucket (null when create_bucket = false)"
  value       = one(aws_s3_bucket.this[*].region)
}

output "replication_role_arn" {
  description = "ARN of the replication role created when create_replication_role = true (else the passed-in replication_role_arn)."
  value       = local.replication_role_arn
}
