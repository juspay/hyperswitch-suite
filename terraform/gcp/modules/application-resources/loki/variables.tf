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
  description = "Name of the GKE cluster hosting Loki"
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
  description = "Kubernetes namespace Loki runs in"
  type        = string
  default     = "observability"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by Loki"
  type        = string
  default     = "loki"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant Loki's service account"
  type        = list(string)
  default     = []
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (typically created by this app's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use_existing_k8s_sa = true; harmless otherwise"
  type        = bool
  default     = true
}

variable "bucket_name" {
  description = "Custom chunks bucket name. If null, auto-generated as '<env>-<project>-loki-chunks'"
  type        = string
  default     = null
}

variable "bucket_location" {
  description = "Location for the chunks bucket"
  type        = string
  default     = "US"
}

variable "bucket_force_destroy" {
  description = "Whether to allow bucket deletion with objects in it"
  type        = bool
  default     = false
}

variable "bucket_lifecycle_rules" {
  description = "Lifecycle rules for the chunks bucket, in the shape expected by simple_bucket"
  type        = any
  default     = []
}

variable "enable_bucket_notifications" {
  description = "Whether to create a Pub/Sub topic + notification for chunk bucket object-create events"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_name_suffix" {
  description = "Suffix appended to this module's DEFAULT bucket names (<env>-<project>-<component>-<role>-<suffix>). GCS bucket names are global, so the same name in two projects collides; the suffix is what lets several environments coexist. null = the first 6 hex characters of sha256(project_id): stable across applies and unique per project. \"\" = no suffix (the names this module produced before the suffix existed - set it on existing deployments to avoid replacing their buckets). Any other value is used as given (1-16 lowercase letters, digits and hyphens). The readable prefix is trimmed so the full name stays within the 63-character GCS limit; the role and the suffix are never trimmed."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name_suffix == null || can(regex("^([a-z0-9]([a-z0-9-]{0,14}[a-z0-9])?)?$", var.bucket_name_suffix))
    error_message = "bucket_name_suffix must be null, an empty string, or 1-16 characters of lowercase letters, digits and hyphens that starts and ends with a letter or digit."
  }
}
