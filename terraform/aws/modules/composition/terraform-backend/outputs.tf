# ============================================================================
# S3 Bucket Outputs
# ============================================================================

output "state_bucket_id" {
  description = "The ID (name) of the state bucket"
  value       = module.state_bucket.bucket_id
}

output "state_bucket_arn" {
  description = "The ARN of the state bucket"
  value       = module.state_bucket.bucket_arn
}

output "state_bucket_region" {
  description = "The region of the state bucket"
  value       = module.state_bucket.bucket_region
}

# ============================================================================
# DynamoDB Table Outputs
# ============================================================================

output "lock_table_id" {
  description = "The ID (name) of the lock table"
  value       = module.lock_table.table_id
}

output "lock_table_name" {
  description = "The name of the lock table"
  value       = module.lock_table.table_name
}

output "lock_table_arn" {
  description = "The ARN of the lock table"
  value       = module.lock_table.table_arn
}

# ============================================================================
# Backend Configuration
# ============================================================================

output "backend_config" {
  description = "Backend configuration object for use in other Terraform deployments"
  value = {
    bucket         = module.state_bucket.bucket_id
    region         = module.state_bucket.bucket_region
    dynamodb_table = module.lock_table.table_name
    encrypt        = true
  }
}

output "backend_config_formatted" {
  description = "Formatted backend configuration for copy-paste into backend.tf files"
  value = <<-EOT
    terraform {
      backend "s3" {
        bucket         = "${module.state_bucket.bucket_id}"
        key            = "<environment>/<region>/<service>/terraform.tfstate"
        region         = "${module.state_bucket.bucket_region}"
        dynamodb_table = "${module.lock_table.table_name}"
        encrypt        = true
      }
    }
  EOT
}
