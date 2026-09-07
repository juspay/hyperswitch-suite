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

# Cross-region disaster recovery

variable "primary_cluster_name" {
  description = <<-EOT
    Fully-qualified resource name of the primary cluster this one replicates
    from (the primary unit's `cluster_name` output, i.e.
    projects/<p>/locations/<r>/clusters/<id>). Leave null - the default - and
    this is a standalone PRIMARY cluster.

    Set it and this becomes a cross-region SECONDARY: continuously replicated
    from the primary, read-only until promoted. This is AlloyDB's counterpart
    of the AWS module's Aurora Global Database support, and the same
    active/passive shape the AWS catalog drives off `values.is_passive` - one
    live unit per region, the passive one pointed at the active one's output.

    A secondary inherits the primary's users, so master_username /
    master_password / secret_manager do nothing here, and read pools cannot be
    created on a secondary cluster at all. Backups (automated and continuous)
    ARE configured independently per cluster and stay in effect.

    Promotion and switchover are NOT Terraform operations - see this module's
    README for the runbook. Unlike Aurora, failing over means a `gcloud alloydb
    clusters switchover` call followed by `terraform apply -refresh-only` and
    moving this variable to the other unit.
  EOT
  type        = string
  default     = null
}

# Instances. A cluster has exactly one primary; read scaling is done with read
# pools, each a single instance resource fronting node_count identical nodes.

variable "primary_instance" {
  description = <<-EOT
    Configuration for the cluster's single primary instance. Every attribute is
    optional; instance_id defaults to '<cluster_id>-primary'.

      availability_type - ZONAL (single zone, no standby - cheapest, dev/test
                          only per Google's own guidance) or REGIONAL
                          (active+standby across zones, automated failover).
      cpu_count         - vCPUs. Valid discrete values: 1, 2, 4, 8, 16, 32, 64,
                          96, 128. 1 is C4A-only and region-limited, so 2 is the
                          practical dev floor; use 8+ for real production load.
      machine_type      - Explicit machine type. cpu_count is still sent
                          alongside it, matching the upstream module's own
                          behaviour (it always populates both).
      gce_zone          - Zone to pin to. Only honoured when availability_type
                          is ZONAL; upstream nulls it out on REGIONAL.
      database_flags    - Postgres flags - AlloyDB's equivalent of an RDS
                          parameter group, e.g.
                          { "alloydb.iam_authentication" = "on" }.
      ssl_mode,         - Transport security, the equivalent of the AWS side's
      require_connectors  rds.force_ssl parameter group entry.
      query_insights_config - The equivalent of Performance Insights.
  EOT

  type = object({
    instance_id               = optional(string)
    display_name              = optional(string)
    availability_type         = optional(string, "REGIONAL")
    cpu_count                 = optional(number, 2)
    machine_type              = optional(string)
    gce_zone                  = optional(string)
    database_flags            = optional(map(string))
    labels                    = optional(map(string), {})
    annotations               = optional(map(string))
    ssl_mode                  = optional(string)
    require_connectors        = optional(bool)
    enable_public_ip          = optional(bool, false)
    enable_outbound_public_ip = optional(bool, false)
    cidr_range                = optional(list(string))
    query_insights_config = optional(object({
      query_string_length     = optional(number)
      record_application_tags = optional(bool)
      record_client_address   = optional(bool)
      query_plans_per_minute  = optional(number)
    }))
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.primary_instance.availability_type)
    error_message = "primary_instance.availability_type must be ZONAL or REGIONAL."
  }

  validation {
    condition     = contains([1, 2, 4, 8, 16, 32, 64, 96, 128], var.primary_instance.cpu_count)
    error_message = "primary_instance.cpu_count must be one of 1, 2, 4, 8, 16, 32, 64, 96, 128."
  }
}

variable "read_pool_instances" {
  description = <<-EOT
    Read pool instances to create under this cluster, keyed by name - the same
    map-of-objects shape the AWS module uses for cluster_instances. The map key
    becomes the instance_id unless one is set explicitly. Empty by default
    (single-instance deployment); populate for read scaling:

      read_pool_instances = {
        read-1 = { node_count = 2, cpu_count = 4 }
        analytics = {
          node_count     = 1
          cpu_count      = 8
          database_flags = { "google.columnar_engine.enabled" = "on" }
        }
      }

    A pool with node_count = 1 is zonal and node_count >= 2 is regional, so
    availability_type and gce_zone are not settable on read pools. Labels and
    annotations are inherited from primary_instance - that is an upstream module
    constraint, not a choice made here.
  EOT

  type = map(object({
    instance_id        = optional(string)
    display_name       = optional(string)
    node_count         = optional(number, 1)
    cpu_count          = optional(number, 2)
    machine_type       = optional(string)
    database_flags     = optional(map(string))
    ssl_mode           = optional(string)
    require_connectors = optional(bool)
    enable_public_ip   = optional(bool, false)
    cidr_range         = optional(list(string))
    query_insights_config = optional(object({
      query_string_length     = optional(number)
      record_application_tags = optional(bool)
      record_client_address   = optional(bool)
      query_plans_per_minute  = optional(number)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for r in var.read_pool_instances : contains([1, 2, 4, 8, 16, 32, 64, 96, 128], r.cpu_count)])
    error_message = "Every read_pool_instances entry needs cpu_count of 1, 2, 4, 8, 16, 32, 64, 96 or 128."
  }

  validation {
    condition     = alltrue([for r in var.read_pool_instances : r.node_count >= 1])
    error_message = "Every read_pool_instances entry needs node_count of at least 1."
  }
}

# Backups

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

# KMS / CMEK - same shape as composition/cloud-sql for consistency

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

# Secret Manager - same shape as composition/cloud-sql's secret_manager toggle

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
