# ============================================================================
# S3 Bucket Outputs
# ============================================================================

output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = module.terraform_backend.state_bucket_id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = module.terraform_backend.state_bucket_arn
}

output "state_bucket_region" {
  description = "Region of the Terraform state bucket"
  value       = module.terraform_backend.state_bucket_region
}

# ============================================================================
# DynamoDB Table Outputs
# ============================================================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.terraform_backend.lock_table_name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = module.terraform_backend.lock_table_arn
}

# ============================================================================
# Backend Configuration
# ============================================================================

output "backend_config" {
  description = "Backend configuration to use in other deployments"
  value       = module.terraform_backend.backend_config
}

# ============================================================================
# Next Steps Instructions
# ============================================================================

output "next_steps" {
  description = "Instructions for what to do next"
  value = <<-EOT

  ========================================
  ✅ Terraform State Backend Created!
  ========================================

  S3 Bucket:      ${module.terraform_backend.state_bucket_id}
  DynamoDB Table: ${module.terraform_backend.lock_table_name}
  Region:         ${module.terraform_backend.state_bucket_region}
  Environment:    PRODUCTION

  ========================================
  🔒 State Locking Enabled
  ========================================

  The DynamoDB table will prevent race conditions when
  multiple team members run Terraform simultaneously.

  ⚠️  PRODUCTION SETTINGS:
  - Bucket deletion protection: ENABLED
  - Point-in-time recovery: ENABLED
  - State versioning: ENABLED

  ========================================
  Next Steps:
  ========================================

  1. Update backend.tf in your production deployments to use this backend.

  2. Initialize backend (if migrating from local):

     terraform init -migrate-state

  3. Or reconfigure backend (if already using S3):

     terraform init -reconfigure

  ⚠️  IMPORTANT: Protect the local terraform.tfstate file in this directory!
      It contains the configuration for your production backend infrastructure.

  ========================================

  EOT
}
