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

variable "cluster_name" {
  description = "Name of the GKE cluster hosting decision-engine"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace decision-engine runs in"
  type        = string
  default     = "hyperswitch"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by decision-engine"
  type        = string
  default     = "decision-engine"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant decision-engine's service account"
  type        = list(string)
  default     = []
}

variable "create_bucket" {
  description = "Whether to create a dedicated GCS bucket for decision-engine"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Custom bucket name. If null, auto-generated as '<env>-<project>-decision-engine-storage'"
  type        = string
  default     = null
}

variable "bucket_location" {
  description = "Location for the dedicated bucket"
  type        = string
  default     = "US"
}

variable "bucket_force_destroy" {
  description = "Whether to allow bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "smtp_secret_id" {
  description = "Secret Manager secret ID holding SMTP credentials (replaces AWS SES). Null skips granting access"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
