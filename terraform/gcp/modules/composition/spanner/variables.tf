variable "project_id" {
  description = "GCP project ID where the Spanner instance is created"
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
  description = <<-EOT
    Region used to derive the default instance_config (regional-<region>) and
    as the location of the optional CMEK keyring.

    Spanner is NOT a VPC-attached regional service the way AlloyDB or
    Memorystore are - there is no network, no Private Service Access range and
    no private IP. This input places the DATA and the KEY, not a network
    interface. Set instance_config directly to use a multi-region
    configuration.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Instance
# -----------------------------------------------------------------------------

variable "instance_id" {
  description = "Spanner instance ID. Must be 6-30 characters. Defaults to '<environment>-<project_name>-spanner'"
  type        = string
  default     = null
}

variable "instance_display_name" {
  description = "Descriptive name shown in the console. Must be 4-30 characters and unique per project. Defaults to instance_id"
  type        = string
  default     = null
}

variable "instance_config" {
  description = <<-EOT
    Spanner instance configuration - the geographic placement and replication
    topology, NOT simply a region. Defaults to 'regional-<region>'.

    Regional configs ('regional-asia-south1') replicate across three zones in
    one region. Multi-region configs ('nam3', 'eur3', 'asia1') replicate across
    regions and carry a higher availability SLA at higher cost.

    Note that 'asia1' is Tokyo/Osaka/Seoul - there is no India multi-region
    config, so an asia-south1 deployment that wants multi-region has to accept
    cross-continent placement. Immutable after creation.
  EOT
  type        = string
  default     = null
}

variable "edition" {
  description = <<-EOT
    STANDARD, ENTERPRISE or ENTERPRISE_PLUS. Editions gate features, not just
    price: incremental backup schedules require ENTERPRISE or above, so
    `databases.<name>.backup_schedule.type = "INCREMENTAL"` fails on STANDARD.
  EOT
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "edition must be one of STANDARD, ENTERPRISE, ENTERPRISE_PLUS."
  }
}

variable "instance_size" {
  description = <<-EOT
    Compute capacity. EXACTLY ONE of the three must be set - the Spanner API
    rejects zero or more than one, and Terraform treats the other two as
    OUTPUT_ONLY once autoscaling is on.

      processing_units - Fine-grained capacity. 1000 PU = 1 node. Below 1000
                         must be a multiple of 100 (100 is the floor and the
                         cheapest way to stand a dev instance up); at or above
                         1000 must be a multiple of 1000.
      num_nodes        - Whole nodes. 1 node = 1000 PU.
      autoscaling      - Managed scaling between limits. min/max must be
                         expressed in the SAME unit (both nodes or both
                         processing units).
  EOT

  type = object({
    processing_units = optional(number)
    num_nodes        = optional(number)

    autoscaling = optional(object({
      min_processing_units = optional(number)
      max_processing_units = optional(number)
      min_nodes            = optional(number)
      max_nodes            = optional(number)

      high_priority_cpu_utilization_percent = optional(number, 65)
      storage_utilization_percent           = optional(number, 95)
    }))
  })

  default = {
    processing_units = 100
  }

  validation {
    condition = length([
      for v in [var.instance_size.processing_units, var.instance_size.num_nodes, var.instance_size.autoscaling] :
      v if v != null
    ]) == 1
    error_message = "Exactly one of instance_size.processing_units, instance_size.num_nodes or instance_size.autoscaling must be set."
  }

  validation {
    condition = var.instance_size.processing_units == null ? true : (
      var.instance_size.processing_units >= 100 &&
      (var.instance_size.processing_units < 1000
        ? var.instance_size.processing_units % 100 == 0
      : var.instance_size.processing_units % 1000 == 0)
    )
    error_message = "instance_size.processing_units must be >= 100, a multiple of 100 below 1000, and a multiple of 1000 at or above 1000."
  }

  validation {
    condition     = var.instance_size.num_nodes == null ? true : var.instance_size.num_nodes >= 1
    error_message = "instance_size.num_nodes must be >= 1."
  }

  validation {
    condition = var.instance_size.autoscaling == null ? true : (
      # Nodes and processing units are alternative units for the same limit;
      # mixing them is accepted by Terraform and rejected by the API.
      (var.instance_size.autoscaling.min_nodes != null && var.instance_size.autoscaling.max_nodes != null &&
      var.instance_size.autoscaling.min_processing_units == null && var.instance_size.autoscaling.max_processing_units == null) ||
      (var.instance_size.autoscaling.min_processing_units != null && var.instance_size.autoscaling.max_processing_units != null &&
      var.instance_size.autoscaling.min_nodes == null && var.instance_size.autoscaling.max_nodes == null)
    )
    error_message = "instance_size.autoscaling must set EITHER min_nodes+max_nodes OR min_processing_units+max_processing_units, not a mix of the two units."
  }
}

variable "default_backup_schedule_type" {
  description = "NONE or AUTOMATIC. AUTOMATIC gives every new database in the instance a default backup schedule, including databases created outside Terraform"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AUTOMATIC"], var.default_backup_schedule_type)
    error_message = "default_backup_schedule_type must be NONE or AUTOMATIC."
  }
}

variable "force_destroy" {
  description = "When destroying the instance, also delete its backups. Required to destroy an instance that has any backup taken manually from the console"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = <<-EOT
    Default Terraform-level delete guard for every database (each database can
    override it). When true, `terraform destroy` refuses to remove the
    database until this is flipped to false and applied FIRST - the same
    two-step constraint gke and alloydb have.

    This is a Terraform-side guard only. For an API-side guard that also
    protects the parent instance, set enable_drop_protection on the database.
  EOT
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------

variable "databases" {
  description = <<-EOT
    Databases to create, keyed by database name. The key must match
    [a-z][-_a-z0-9]*[a-z0-9] and is used verbatim as the database ID.

      database_dialect  - POSTGRESQL (the default here) or GOOGLE_STANDARD_SQL.
                          POSTGRESQL gives PostgreSQL syntax and semantics; it
                          does NOT give the PostgreSQL wire protocol, so libpq
                          clients still need PGAdapter in front. See README.
      ddl               - Statements executed atomically with database
                          creation. Must be written in the dialect above.
                          Terraform does NOT drift-detect this field: appending
                          statements is an in-place update, but editing or
                          removing an existing one plans a REPLACEMENT of the
                          database, which destroys the data.
      version_retention_period - PITR window. Between 1h and 7d.
      deletion_protection      - Overrides the module-level default.
      enable_drop_protection   - API-side guard. Unlike deletion_protection it
                          also blocks deletion of the parent INSTANCE, and it
                          applies to every interface, not just Terraform.
      kms_key_name      - Per-database CMEK, overriding the module-level key.
      backup_schedule   - Optional schedule; see the type below. INCREMENTAL
                          requires edition ENTERPRISE or above.
  EOT

  type = map(object({
    database_dialect         = optional(string, "POSTGRESQL")
    ddl                      = optional(list(string), [])
    version_retention_period = optional(string, "3d")
    deletion_protection      = optional(bool)
    enable_drop_protection   = optional(bool, false)
    kms_key_name             = optional(string)

    backup_schedule = optional(object({
      name               = optional(string)
      cron               = optional(string, "0 2 * * *")
      retention_duration = optional(string, "1209600s") # 14 days
      type               = optional(string, "FULL")
      encryption_type    = optional(string, "USE_DATABASE_ENCRYPTION")
    }))
  }))

  default = {
    hyperswitch = {}
  }

  validation {
    condition = alltrue([
      for k, d in var.databases : contains(["POSTGRESQL", "GOOGLE_STANDARD_SQL"], d.database_dialect)
    ])
    error_message = "Each databases.<name>.database_dialect must be POSTGRESQL or GOOGLE_STANDARD_SQL."
  }

  validation {
    condition = alltrue([
      for k, d in var.databases : can(regex("^[a-z][-_a-z0-9]*[a-z0-9]$", k))
    ])
    error_message = "Each databases key must be a valid Spanner database ID matching [a-z][-_a-z0-9]*[a-z0-9]."
  }

  validation {
    condition = alltrue([
      for k, d in var.databases :
      d.backup_schedule == null ? true : contains(["FULL", "INCREMENTAL"], d.backup_schedule.type)
    ])
    error_message = "Each databases.<name>.backup_schedule.type must be FULL or INCREMENTAL."
  }
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
# Spanner has no username/password and no bootstrap user - access is entirely
# IAM. There is deliberately no master_username / master_password /
# secret_manager input here, unlike composition/alloydb and
# composition/cloud-sql.

variable "instance_iam_members" {
  description = "Instance-level IAM grants, e.g. [{ role = \"roles/spanner.viewer\", member = \"serviceAccount:...\" }]. Non-authoritative - each entry adds one binding and leaves others alone"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

variable "database_iam_members" {
  description = <<-EOT
    Database-level IAM grants. `database` must be a key of var.databases.

    roles/spanner.databaseUser is the role an application (or PGAdapter acting
    on its behalf) needs to read and write. Non-authoritative, like
    instance_iam_members.
  EOT
  type = list(object({
    database = string
    role     = string
    member   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for m in var.database_iam_members : contains(keys(var.databases), m.database)
    ])
    error_message = "Every database_iam_members[*].database must be a key of var.databases."
  }
}

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------

variable "kms" {
  description = "Set create=true to have this module create a KMS keyring and key for database encryption. Ignored when encryption_key_name is set"
  type = object({
    create          = optional(bool, false)
    keyring_name    = optional(string)
    key_name        = optional(string, "spanner-key")
    rotation_period = optional(string)
  })
  default = null
}

variable "encryption_key_name" {
  description = <<-EOT
    Self-link of an existing CMEK key applied to every database that does not
    set its own kms_key_name. Takes precedence over var.kms.

    The key must live in the SAME location as the data. That is var.region for
    a regional instance_config; a multi-region config needs one key per region
    supplied through the API's kms_key_names (plural), which this module does
    not expose - use GOOGLE_DEFAULT_ENCRYPTION there.
  EOT
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to the instance"
  type        = map(string)
  default     = {}
}
