output "source_bucket_id" {
  description = "The ID (name) of the source bucket."
  value       = module.source.bucket_id
}

output "source_bucket_arn" {
  description = "The ARN of the source bucket."
  value       = module.source.bucket_arn
}

output "destination_bucket_id" {
  description = "The ID (name) of the destination (replica) bucket."
  value       = coalesce(one(module.destination[*].bucket_id), var.destination_bucket_name)
}

output "destination_bucket_arn" {
  description = "The ARN of the destination (replica) bucket."
  value       = local.destination_bucket_arn
}

output "replication_role_arn" {
  description = "ARN of the IAM role S3 assumes for replication."
  value       = module.source.replication_role_arn
}
