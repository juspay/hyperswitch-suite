variable "project_id" {
  description = "GCP project ID where the cluster is created"
  type        = string
}

variable "project_name" {
  description = "Project name for labeling and naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "region" {
  description = "Region (AlloyDB 'location') for the cluster"
  type        = string
}

variable "network_id" {
  description = "Self-link/ID of the VPC network to attach the cluster to (requires Private Service Access to already be configured, see composition/vpc-network)"
  type        = string
}

variable "allocated_ip_range" {
  description = "Name (not CIDR) of the Private Service Access reserved IP range - composition/vpc-network exposes this as private_service_access_range_name"
  type        = string
}

variable "cluster_id" {
  description = "AlloyDB cluster ID. Defaults to '<environment>-<project_name>-alloydb'"
  type        = string
  default     = null
}

variable "database_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "POSTGRES_15"
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the cluster"
  type        = bool
  default     = true
}

variable "master_username" {
  description = "Name of the cluster's bootstrap admin user"
  type        = string
  default     = "hyperswitch_admin"
}

variable "master_password" {
  description = "Password for the bootstrap admin user. Leave null to auto-generate a random one (AlloyDB has no built-in auto-generation like Cloud SQL - this module replicates it with its own random_password resource)"
  type        = string
  default     = null
  sensitive   = true
}

# ============================================================================
# Primary instance sizing
# ============================================================================

variable "primary_availability_type" {
  description = "ZONAL (single zone, no standby - cheapest, dev/test only per Google's own guidance) or REGIONAL (active+standby across zones, automated failover - the production-grade default)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.primary_availability_type)
    error_message = "primary_availability_type must be ZONAL or REGIONAL."
  }
}

variable "primary_cpu_count" {
  description = "vCPU count for the primary instance. Valid discrete values (N2/N2D families): 2, 4, 8, 16, 32, 48, 64, ... - 1 is only available on the region-limited C4A family, so 2 is the practical cheapest default. Bump meaningfully (8+) for real production load."
  type        = number
  default     = 2
}

variable "primary_machine_type" {
  description = "Explicit machine type for the primary instance, overriding primary_cpu_count's implied sizing. Leave null to size purely off primary_cpu_count."
  type        = string
  default     = null
}

# ============================================================================
# Read pool (production HA read scaling) - empty by default
# ============================================================================

variable "read_pool_instances" {
  description = "Read pool instances to create under this same cluster, for read scaling / production HA. Empty by default (minimal single-instance deployment) - populate for a production-grade setup, e.g. [{ instance_id = \"read-1\", node_count = 2, cpu_count = 4 }]."
  type = list(object({
    instance_id = string
    node_count  = number
    cpu_count   = optional(number, 2)
  }))
  default = []
}

# ============================================================================
# Backups
# ============================================================================

variable "continuous_backup_enabled" {
  description = "Whether to enable continuous backup (AlloyDB's point-in-time recovery equivalent)"
  type        = bool
  default     = true
}

variable "continuous_backup_recovery_window_days" {
  description = "Number of days of continuous backup / PITR window to retain"
  type        = number
  default     = 14
}

variable "automated_backup_enabled" {
  description = "Whether to enable daily automated (snapshot) backups"
  type        = bool
  default     = true
}

variable "automated_backup_retention_count" {
  description = "Number of automated daily backups to retain"
  type        = number
  default     = 14
}

variable "automated_backup_start_hour" {
  description = "UTC hour (0-23) the daily automated backup window starts"
  type        = number
  default     = 2
}

# ============================================================================
# KMS / CMEK - same shape as composition/cloud-sql for consistency
# ============================================================================

variable "kms" {
  description = "CMEK configuration. Set create=true to have this module create a KMS keyring/key for cluster encryption"
  type = object({
    create          = optional(bool, false)
    keyring_name    = optional(string)
    key_name        = optional(string, "alloydb")
    rotation_period = optional(string)
  })
  default = null
}

variable "encryption_key_name" {
  description = "Self-link of an existing KMS CryptoKey for cluster encryption. Takes precedence over var.kms.create"
  type        = string
  default     = null
}

# ============================================================================
# Secret Manager - same shape as composition/cloud-sql's secret_manager toggle
# ============================================================================

variable "secret_manager" {
  description = "Set create=true to have this module store the auto-generated master password in Secret Manager. Only takes effect when master_password is left unset."
  type = object({
    create    = optional(bool, false)
    secret_id = optional(string)
  })
  default = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
