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
  description = "Name of the GKE cluster hosting the collector"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace the collector runs in"
  type        = string
  default     = "observability"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by the collector"
  type        = string
  default     = "otel-collector"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant the collector's service account"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
