output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = module.terraform_state_bucket.bucket_id
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket"
  value       = module.terraform_state_bucket.bucket_arn
}

output "state_bucket_region" {
  description = "Region of the Terraform state bucket"
  value       = module.terraform_state_bucket.bucket_region
}

output "backend_config" {
  description = "Backend configuration to use in other deployments"
  value = {
    bucket  = module.terraform_state_bucket.bucket_id
    region  = module.terraform_state_bucket.bucket_region
    encrypt = true
  }
}

output "next_steps" {
  description = "Instructions for what to do next"
  value = <<-EOT

  ========================================
  ✅ Terraform State Bucket Created!
  ========================================

  Bucket Name: ${module.terraform_state_bucket.bucket_id}
  Region:      ${module.terraform_state_bucket.bucket_region}
  ARN:         ${module.terraform_state_bucket.bucket_arn}

  ========================================
  Next Steps:
  ========================================

  1. Update backend.tf in your deployments:

     cd ../live/dev/eu-central-1/squid-proxy/

     # Update backend.tf to:
     terraform {
       backend "s3" {
         bucket  = "${module.terraform_state_bucket.bucket_id}"
         key     = "dev/eu-central-1/squid-proxy/terraform.tfstate"
         region  = "${module.terraform_state_bucket.bucket_region}"
         encrypt = true
       }
     }

  2. Migrate state from local to S3:

     terraform init -migrate-state

  3. Confirm migration by typing: yes

  4. Verify state is in S3:

     aws s3 ls s3://${module.terraform_state_bucket.bucket_id}/dev/eu-central-1/squid-proxy/

  ========================================

  EOT
}
