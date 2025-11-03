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
  Terraform State Backend Created!
  ========================================

  S3 Bucket:      ${module.terraform_backend.state_bucket_id}
  DynamoDB Table: ${module.terraform_backend.lock_table_name}
  Region:         ${module.terraform_backend.state_bucket_region}

  ========================================
  State Locking Enabled
  ========================================

  The DynamoDB table will prevent race conditions when
  multiple team members run Terraform simultaneously.

  ========================================
  Next Steps:
  ========================================

  1. Update backend.tf in your deployments:

     cd ../live/dev/eu-central-1/squid-proxy/

     # Update backend.tf to:
     terraform {
       backend "s3" {
         bucket         = "${module.terraform_backend.state_bucket_id}"
         key            = "dev/eu-central-1/squid-proxy/terraform.tfstate"
         region         = "${module.terraform_backend.state_bucket_region}"
         dynamodb_table = "${module.terraform_backend.lock_table_name}"
         encrypt        = true
       }
     }

  2. Initialize backend (if migrating from local):

     terraform init -migrate-state

  3. Or reconfigure backend (if already using S3):

     terraform init -reconfigure

  4. Verify state is in S3:

     aws s3 ls s3://${module.terraform_backend.state_bucket_id}/dev/eu-central-1/squid-proxy/

  5. Test state locking (optional):

     # In one terminal:
     terraform plan   # This acquires a lock

     # In another terminal (will fail with lock error):
     terraform plan   # This shows locking is working!

  ========================================

  EOT
}
