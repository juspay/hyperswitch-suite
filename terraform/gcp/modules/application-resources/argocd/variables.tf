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
  description = "Name of the GKE cluster hosting ArgoCD"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is deployed"
  type        = string
  default     = "argocd"
}

variable "argocd_service_accounts" {
  description = "List of ArgoCD Kubernetes service accounts bound to Workload Identity. Only the first is bound directly (Workload Identity is 1:1 GSA<->KSA); grant the rest via kubectl annotation if they should share the same GSA"
  type        = list(string)
  default = [
    "argocd-application-controller",
    "argocd-applicationset-controller",
    "argocd-server",
  ]
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant ArgoCD's service account"
  type        = list(string)
  default     = []
}

variable "cross_project_target_service_accounts" {
  description = "List of fully qualified service account IDs (in other projects) that ArgoCD is allowed to impersonate for cross-project deployments"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
