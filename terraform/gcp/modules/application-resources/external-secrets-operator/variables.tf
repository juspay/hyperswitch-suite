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
  description = "Kubernetes namespace the operator runs in"
  type        = string
  default     = "external-secrets-operator"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by the operator"
  type        = string
  default     = "external-secrets-sa"
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (typically created by the operator's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use_existing_k8s_sa = true; harmless otherwise"
  type        = bool
  default     = true
}

# Secret Manager access

variable "scope_to_project" {
  description = <<-EOT
    Whether to grant project-wide roles/secretmanager.secretAccessor. True is
    the closest equivalent of the AWS module, whose inline policy always
    covers every secret in the account/region.

    Set false and populate secret_ids for least privilege. Setting false with
    an empty secret_ids grants the operator no Secret Manager access at all -
    it will start cleanly and then fail every ExternalSecret it reconciles
    with a permission error, which is not an obvious symptom.
  EOT
  type        = bool
  default     = true
}

variable "secret_ids" {
  description = "Secret Manager secret IDs to grant per-secret accessor access to, in addition to (or instead of) the project-wide role"
  type        = list(string)
  default     = []
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant the operator's service account (e.g. roles/secretmanager.viewer for the PushSecret/discovery paths)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
