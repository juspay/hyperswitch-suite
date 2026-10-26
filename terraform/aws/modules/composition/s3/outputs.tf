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
  description = "ARN of the forward (source -> replica) replication IAM role (null when replication is disabled)"
  value       = try(aws_iam_role.replication["fwd"].arn, null)
}

output "replication_role_arns" {
  description = "Map of replication direction (fwd/rev) to IAM role ARN for all active directions"
  value       = { for k, role in aws_iam_role.replication : k => role.arn }
}

output "replication_enabled" {
  description = "Whether cross-region replication is configured"
  value       = local.replication_enabled
}

output "bidirectional_replication_enabled" {
  description = "Whether two-way (replica -> source) replication is configured"
  value       = local.bidirectional
}
