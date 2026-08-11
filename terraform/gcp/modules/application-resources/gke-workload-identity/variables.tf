variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
}

variable "app_name" {
  description = "Application name (e.g. hyperswitch, control-centre)"
  type        = string
}

variable "service_account_id" {
  description = "Custom Google service account ID. If null, auto-generated as '<project>-<env>-<app>-sa'"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting the workload"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace of the service account to bind"
  type        = string
}

variable "k8s_service_account_name" {
  description = "Name of the Kubernetes service account to bind via Workload Identity"
  type        = string
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (skip creating it)"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the GCP service account email"
  type        = bool
  default     = true
}

variable "project_roles" {
  description = "List of project-level IAM roles to grant the Google service account (e.g. ['roles/logging.logWriter'])"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Optional companion GCS bucket
# ==============================================================================

variable "create_bucket" {
  description = "Whether to create a companion GCS bucket alongside the service account"
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "Custom bucket name. If null, auto-generated as '<project>-<env>-<app>-storage'"
  type        = string
  default     = null
}

variable "bucket_location" {
  description = "Location for the companion bucket"
  type        = string
  default     = "US"
}

variable "bucket_force_destroy" {
  description = "Whether to allow bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "bucket_enable_versioning" {
  description = "Enable versioning for the companion bucket"
  type        = bool
  default     = false
}
