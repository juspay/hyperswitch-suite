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
  description = "GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider"
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
  description = "Whether to create a dedicated AlloyDB cluster for Grafana"
  type        = bool
  default     = true
}

variable "database_config" {
  description = <<-EOT
    Configuration for Grafana's dedicated AlloyDB cluster (composition/alloydb).

    allocated_ip_range is REQUIRED whenever create_database is true - AlloyDB
    attaches over Private Service Access and composition/alloydb takes the
    reserved range by name, not by CIDR (composition/vpc-network exposes it as
    private_service_access_range_name). It is typed optional purely so callers
    that set create_database = false need not supply it: Terraform validates
    full object conformance regardless of the count-gated branch that reads it.

    There is deliberately no database_name attribute, unlike the Cloud SQL
    shape this replaced. The google provider ships no resource for an
    individual AlloyDB database (only alloydb_cluster / _instance / _user /
    _backup), so the cluster's bootstrap `postgres` database is what exists
    after apply and any additional logical database is a SQL-level concern.

    Cloud SQL's tier and disk_size have no AlloyDB counterpart either - size
    the primary with cpu_count (or machine_type), and storage is managed by
    the service.
  EOT
  type = object({
    network_id          = string
    allocated_ip_range  = optional(string)
    cluster_id          = optional(string)
    database_version    = optional(string)
    availability_type   = optional(string)
    cpu_count           = optional(number)
    machine_type        = optional(string)
    database_flags      = optional(map(string))
    deletion_protection = optional(bool)
    master_username     = optional(string)
    master_password     = optional(string)
    encryption_key_name = optional(string)
    secret_manager = optional(object({
      create    = optional(bool, false)
      secret_id = optional(string)
    }))
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
