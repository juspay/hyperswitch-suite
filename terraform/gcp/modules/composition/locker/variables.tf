variable "project_id" {
  description = "GCP project ID where resources are created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "region" {
  description = "Region for the AlloyDB cluster and the KMS keyring"
  type        = string
}

# GKE cluster hosting the locker workload

variable "cluster_name" {
  description = "Name of the GKE cluster the locker runs on"
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
  description = "Kubernetes namespace the locker workload runs in"
  type        = string
  default     = "locker"
}

variable "k8s_service_account_name" {
  description = "Kubernetes service account name used by the locker workload"
  type        = string
  default     = "locker"
}

variable "use_existing_k8s_sa" {
  description = "Whether the Kubernetes service account already exists (typically created by the locker's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply"
  type        = bool
  default     = false
}

variable "annotate_k8s_sa" {
  description = "Whether to annotate the Kubernetes service account with the Google service account email"
  type        = bool
  default     = true
}

variable "additional_project_roles" {
  description = "Project-level IAM roles to grant the locker's service account on top of the AlloyDB connectivity pair (roles/alloydb.client and roles/serviceusage.serviceUsageConsumer) this module always grants"
  type        = list(string)
  default     = []
}

# Dedicated AlloyDB cluster

variable "create_database" {
  description = "Whether to create the vault's dedicated AlloyDB cluster. Setting false leaves this module creating only the service account and its IAM, for callers pointing the vault at a database managed elsewhere"
  type        = bool
  default     = true
}

variable "database_config" {
  description = <<-EOT
    Configuration for the vault's dedicated AlloyDB cluster (composition/alloydb).
    Same object shape as application-resources/grafana and
    application-resources/superposition use for their own dedicated clusters.

    allocated_ip_range is REQUIRED whenever create_database is true - AlloyDB
    attaches over Private Service Access and composition/alloydb takes the
    reserved range by name, not by CIDR (composition/vpc-network exposes it as
    private_service_access_range_name). It is typed optional purely so callers
    that set create_database = false need not supply it: Terraform validates
    full object conformance regardless of the count-gated branch that reads it.

    There is deliberately no database_name attribute. The google provider
    ships no resource for an individual AlloyDB database (only
    alloydb_cluster / _instance / _user / _backup), so the cluster's bootstrap
    `postgres` database is what exists after apply and creating the vault's
    own logical database is a SQL-level step.

    secret_manager defaults to { create = true } here, unlike
    composition/alloydb's own default of null: a pod has no instance-metadata
    channel to receive a module-generated password through, so Secret Manager
    is the only delivery path. Leave master_password unset to use it.
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
    secret_manager = optional(object({
      create    = optional(bool, true)
      secret_id = optional(string)
    }))
  })
  default  = { network_id = null }
  nullable = false
}

# CMEK

variable "create_kms_key" {
  description = "Whether to create a dedicated KMS keyring and key for the vault's AlloyDB cluster. Ignored when encryption_key_name is set"
  type        = bool
  default     = true
}

variable "encryption_key_name" {
  description = "Self-link of an existing KMS CryptoKey to encrypt the vault's cluster with. Takes precedence over create_kms_key"
  type        = string
  default     = null
}

variable "kms_keyring_name" {
  description = "Name of the created keyring. Defaults to '<environment>-<project_name>-locker-keyring'"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "Name of the created key inside the keyring"
  type        = string
  default     = "locker"
}

variable "kms_protection_level" {
  description = "Protection level for the created key: SOFTWARE or HSM. HSM is the stricter choice for a PCI-DSS-scoped vault and costs more per key version"
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.kms_protection_level)
    error_message = "kms_protection_level must be SOFTWARE or HSM."
  }
}

variable "kms_rotation_period" {
  description = "Rotation period for the created key, in seconds with an 's' suffix. Defaults to 90 days"
  type        = string
  default     = "7776000s"
}

variable "kms_prevent_destroy" {
  description = "Whether to protect the created key from destruction. Leave true outside throwaway environments - AlloyDB backups are encrypted under this key and become unreadable without it"
  type        = bool
  default     = true
}

variable "grant_kms_access" {
  description = "Whether to grant the locker's service account cryptoKeyEncrypterDecrypter on the CMEK key, for application-level card encryption. Off by default - the key's purpose is encrypting the AlloyDB cluster, and the vault normally manages its own data-encryption keys internally"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
