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
  description = "Name of the GKE cluster hosting Superposition"
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
  description = "Kubernetes namespace Superposition runs in"
  type        = string
  default     = "hyperswitch"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by Superposition"
  type        = string
  default     = "superposition"
}

variable "additional_project_roles" {
  description = "Additional project-level IAM roles to grant Superposition's service account"
  type        = list(string)
  default     = []
}

variable "create_database" {
  description = "Whether to create a dedicated Cloud SQL database for Superposition"
  type        = bool
  default     = true
}

variable "database_config" {
  description = "Configuration for Superposition's dedicated Cloud SQL database (composition/cloud-sql)"
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

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
