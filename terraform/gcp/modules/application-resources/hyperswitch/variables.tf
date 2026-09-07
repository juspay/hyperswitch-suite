variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
  default     = "hyperswitch"
}

variable "public_domain" {
  description = "Public domain name used to access Hyperswitch. Passed through as an output for wiring into DNS/certificate config"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting Hyperswitch"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider"
  type        = string
  sensitive   = true
}

variable "k8s_namespace" {
  description = "Kubernetes namespace Hyperswitch runs in"
  type        = string
  default     = "hyperswitch"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by Hyperswitch"
  type        = string
  default     = "hyperswitch"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant Hyperswitch's service account"
  type        = list(string)
  default     = []
}

# Feature: KMS Key

variable "kms" {
  description = "KMS configuration. Set create=true to create a keyring/key and grant the service account encrypt/decrypt access"
  type = object({
    create          = optional(bool, false)
    location        = optional(string)
    keyring_name    = optional(string)
    key_name        = optional(string)
    rotation_period = optional(string)
  })
  default = null
}

# Feature: GCS Buckets

variable "gcs_dashboard_themes" {
  description = "GCS bucket configuration for dashboard themes. Set create=true to create a new bucket, or create=false with bucket_name set to an existing bucket to grant access to it"
  type = object({
    create             = optional(bool, false)
    bucket_name        = optional(string)
    location           = optional(string, "US")
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = null
}

variable "gcs_file_uploads" {
  description = "GCS bucket configuration for file uploads. Set create=true to create a new bucket, or create=false with bucket_name set to an existing bucket to grant access to it"
  type = object({
    create             = optional(bool, false)
    bucket_name        = optional(string)
    location           = optional(string, "US")
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
  })
  default = null
}

# Feature: SMTP credentials

variable "smtp_secret_id" {
  description = "Secret Manager secret ID holding SMTP credentials. Null disables granting access"
  type        = string
  default     = null
}

# Feature: Secret Manager

variable "secret_ids" {
  description = "List of Secret Manager secret IDs to grant the service account access to"
  type        = list(string)
  default     = []
}

# Feature: Cloud Functions

variable "cloud_functions" {
  description = "Cloud Functions configuration. Set enabled=true and list function_names to grant invoker access"
  type = object({
    enabled        = optional(bool, false)
    location       = optional(string)
    function_names = optional(list(string), [])
  })
  default = null
}

# Feature: Cross-Project Impersonation (replaces AWS cross-account assume role)

variable "cross_project_assume" {
  description = "Cross-project impersonation configuration. Set enabled=true and list target_service_accounts to grant roles/iam.serviceAccountTokenCreator on them"
  type = object({
    enabled                 = optional(bool, false)
    target_service_accounts = optional(list(string), [])
  })
  default = null
}

# Feature: Additional Custom Roles (replaces AWS additional_iam_policies)

variable "additional_custom_role_ids" {
  description = "List of project-level custom role IDs (e.g. from application-resources/shared-iam-roles) to grant the service account"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
