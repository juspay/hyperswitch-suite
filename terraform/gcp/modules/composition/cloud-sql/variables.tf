variable "project_id" {
  description = "GCP project ID where the instance is created"
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
  description = "Region for the primary Cloud SQL instance"
  type        = string
}

variable "network_id" {
  description = "Self-link/ID of the VPC network to attach the instance to (requires Private Service Access to already be configured, see composition/vpc-network)"
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance. Defaults to '<environment>-<project_name>-sql-pg'"
  type        = string
  default     = null
}

variable "database_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "POSTGRES_15"
}

variable "edition" {
  description = "Edition of the instance: ENTERPRISE or ENTERPRISE_PLUS"
  type        = string
  default     = "ENTERPRISE"
}

variable "tier" {
  description = "Machine tier for the instance (e.g. db-custom-4-16384)"
  type        = string
  default     = "db-custom-2-8192"
}

variable "availability_type" {
  description = "Availability type: ZONAL or REGIONAL (REGIONAL enables HA, the Multi-AZ equivalent)"
  type        = string
  default     = "REGIONAL"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Disk type: PD_SSD or PD_HDD"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Whether to enable disk autoresize"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the instance"
  type        = bool
  default     = true
}

variable "database_flags" {
  description = "List of database flags to set on the instance"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backup_start_time" {
  description = "HH:MM start time for the daily automated backup window (UTC)"
  type        = string
  default     = "02:00"
}

variable "enable_point_in_time_recovery" {
  description = "Whether to enable point-in-time recovery (WAL archiving)"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days of transaction logs to retain for point-in-time recovery"
  type        = string
  default     = "7"
}

variable "retained_backups" {
  description = "Number of automated backups to retain"
  type        = number
  default     = 30
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "hyperswitch"
}

variable "master_username" {
  description = "Name of the default database user to create"
  type        = string
  default     = "hyperswitch_admin"
}

variable "master_password" {
  description = "Password for the default database user. Leave null to auto-generate a random password"
  type        = string
  default     = null
  sensitive   = true
}

variable "random_instance_name" {
  description = "Whether to append a random suffix to the instance name"
  type        = bool
  default     = false
}

variable "read_replicas" {
  description = "List of read replicas to create, in the shape expected by terraform-google-modules/sql-db//modules/postgresql. Cross-region entries are the closest GCP equivalent to an Aurora Global Cluster secondary region."
  type        = any
  default     = []
}

variable "module_depends_on" {
  description = "List of resources this module should depend on (e.g. the Private Service Access connection from composition/vpc-network)"
  type        = list(any)
  default     = []
}

# ============================================================================
# KMS / CMEK
# ============================================================================

variable "kms" {
  description = "CMEK configuration. Set create=true to have this module create a KMS keyring/key for disk encryption"
  type = object({
    create          = optional(bool, false)
    keyring_name    = optional(string)
    key_name        = optional(string, "cloud-sql")
    rotation_period = optional(string)
  })
  default = null
}

variable "encryption_key_name" {
  description = "Self-link of an existing KMS CryptoKey for disk encryption. Takes precedence over var.kms.create"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
