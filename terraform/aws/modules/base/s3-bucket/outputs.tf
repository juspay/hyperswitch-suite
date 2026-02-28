output "bucket_id" {
  description = "The ID (name) of the bucket"
  value       = try(aws_s3_bucket.this[0].id, "")
}

output "bucket_name" {
  description = "The name of the bucket (alias for bucket_id)"
  value       = try(aws_s3_bucket.this[0].id, "")
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = try(aws_s3_bucket.this[0].arn, "")
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = try(aws_s3_bucket.this[0].bucket_domain_name, "")
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name"
  value       = try(aws_s3_bucket.this[0].bucket_regional_domain_name, "")
}

output "bucket_region" {
  description = "The AWS region of the bucket"
  value       = try(aws_s3_bucket.this[0].region, "")
}
