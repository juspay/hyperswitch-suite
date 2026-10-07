output "source_bucket_id" {
  description = "Name/ID of the source bucket"
  value       = module.source_bucket.s3_bucket_id
}

output "source_bucket_arn" {
  description = "ARN of the source bucket"
  value       = module.source_bucket.s3_bucket_arn
}

output "source_bucket_regional_domain_name" {
  description = "Region-specific domain name of the source bucket"
  value       = module.source_bucket.s3_bucket_bucket_regional_domain_name
}

output "replica_bucket_id" {
  description = "Name/ID of the replica bucket (null when replication is disabled)"
  value       = try(module.replica_bucket[0].s3_bucket_id, null)
}

output "replica_bucket_arn" {
  description = "ARN of the replica bucket (null when replication is disabled)"
  value       = try(module.replica_bucket[0].s3_bucket_arn, null)
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for replication (null when replication is disabled)"
  value       = try(aws_iam_role.replication[0].arn, null)
}

output "replication_enabled" {
  description = "Whether cross-region replication is configured"
  value       = local.replication_enabled
}
