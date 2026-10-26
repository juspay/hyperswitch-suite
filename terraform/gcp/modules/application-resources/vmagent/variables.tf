variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting vmagent"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Kubernetes namespace vmagent runs in"
  type        = string
  default     = "monitoring"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by vmagent (the VictoriaMetrics operator names it vmagent-<fullnameOverride>)"
  type        = string
  default     = "vmagent-victoria-metrics"
}

variable "project_roles" {
  description = "Project-level IAM roles granted to vmagent's service account"
  type        = list(string)
  default     = ["roles/compute.viewer"]
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account is created elsewhere (the monitoring Helm release). Defaults to true so Terraform only creates the GCP-side identity and binding"
  type        = bool
  default     = true
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use_existing_k8s_sa = true; Helm sets the annotation, so this defaults to false"
  type        = bool
  default     = false
}
