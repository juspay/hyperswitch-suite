# GCS Bucket Outputs

output "state_bucket_name" {
  description = "The name of the state bucket"
  value       = module.state_bucket.name
}

output "state_bucket_url" {
  description = "The gsutil URI of the state bucket (gs://<name>)"
  value       = module.state_bucket.url
}

output "state_bucket_location" {
  description = "The location of the state bucket"
  value       = var.location
}

# Backend Configuration

output "backend_config" {
  description = "Backend configuration object for use in other Terraform deployments"
  value = {
    bucket = module.state_bucket.name
  }
}

output "backend_config_formatted" {
  description = "Formatted backend configuration for copy-paste into backend.tf files"
  value       = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "${module.state_bucket.name}"
        prefix = "<environment>/<region>/<service>"
      }
    }
  EOT
}
