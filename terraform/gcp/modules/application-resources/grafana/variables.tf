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

variable "region" {
  description = "Region for the dedicated Cloud SQL database"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster hosting Grafana"
  type        = string
}

variable "cluster_location" {
  description = "Location (region or zone) of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's own kubernetes provider (see main.tf header comment)"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate, base64-encoded - required to configure this module's own kubernetes provider (see main.tf header comment)"
  type        = string
  sensitive   = true
}

variable "k8s_namespace" {
  description = "Kubernetes namespace Grafana runs in"
  type        = string
  default     = "monitoring"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by Grafana"
  type        = string
  default     = "grafana"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant Grafana's service account"
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

variable "create_database" {
  description = "Whether to create a dedicated Cloud SQL database for Grafana"
  type        = bool
  default     = true
}

variable "database_config" {
  description = "Configuration for Grafana's dedicated Cloud SQL database (composition/cloud-sql)"
  type = object({
    network_id          = string
    instance_name       = optional(string)
    database_version    = optional(string)
    tier                = optional(string)
    availability_type   = optional(string)
    disk_size           = optional(number)
    deletion_protection = optional(bool)
    database_name       = optional(string)
    master_username     = optional(string)
    master_password     = optional(string)
    encryption_key_name = optional(string)
  })
}

variable "host_domains" {
  description = "Map of logical name to hostname this Grafana instance is served on, passed through as an output for wiring into composition/istio or composition/load-balancer"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
