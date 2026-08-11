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
