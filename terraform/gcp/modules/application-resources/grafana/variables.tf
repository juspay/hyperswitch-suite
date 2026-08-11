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
