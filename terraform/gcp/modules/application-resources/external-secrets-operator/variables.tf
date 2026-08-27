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
  description = "Name of the GKE cluster hosting the operator"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace the operator runs in"
  type        = string
  default     = "external-secrets"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by the operator"
  type        = string
  default     = "external-secrets"
}

variable "scope_to_project" {
  description = "Whether to grant project-wide roles/secretmanager.secretAccessor. Set false and use secret_ids for least-privilege, per-secret access instead"
  type        = bool
  default     = true
}

variable "secret_ids" {
  description = "List of specific Secret Manager secret IDs to grant access to (in addition to, or instead of, the project-wide role)"
  type        = list(string)
  default     = []
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant the operator's service account"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
