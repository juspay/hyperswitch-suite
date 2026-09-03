# Service Account Outputs

output "service_account_email" {
  description = "Email of Hyperswitch's Google service account"
  value       = module.workload_identity.gcp_service_account_email
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name"
  value       = module.workload_identity.k8s_service_account_name
}

output "public_domain" {
  description = "Passthrough of var.public_domain"
  value       = var.public_domain
}

# KMS Outputs

output "kms_enabled" {
  description = "Whether a KMS key was created for this application"
  value       = local.kms_enabled
}

output "kms_key_name" {
  description = "Self-link of the KMS key, if created"
  value       = local.kms_enabled ? module.kms[0].keys[coalesce(var.kms.key_name, "hyperswitch")] : null
}

# GCS Bucket Outputs

output "dashboard_themes_bucket_enabled" {
  description = "Whether the dashboard-themes feature is enabled"
  value       = local.gcs_dashboard_themes_enabled
}

output "dashboard_themes_bucket_name" {
  description = "Name of the dashboard-themes bucket (created or existing), if enabled"
  value       = local.gcs_dashboard_themes_enabled ? (var.gcs_dashboard_themes.create ? module.dashboard_themes_bucket[0].name : var.gcs_dashboard_themes.bucket_name) : null
}

output "file_uploads_bucket_enabled" {
  description = "Whether the file-uploads feature is enabled"
  value       = local.gcs_file_uploads_enabled
}

output "file_uploads_bucket_name" {
  description = "Name of the file-uploads bucket (created or existing), if enabled"
  value       = local.gcs_file_uploads_enabled ? (var.gcs_file_uploads.create ? module.file_uploads_bucket[0].name : var.gcs_file_uploads.bucket_name) : null
}

# Other Feature Outputs

output "smtp_enabled" {
  description = "Whether SMTP secret access was granted"
  value       = local.smtp_enabled
}

output "secrets_manager_enabled" {
  description = "Whether Secrets Manager access was granted"
  value       = local.secrets_manager_enabled
}

output "lambda_enabled" {
  description = "Whether Cloud Functions invoker access was granted"
  value       = local.lambda_enabled
}

output "cross_project_assume_enabled" {
  description = "Whether cross-project impersonation was granted"
  value       = local.cross_project_enabled
}
