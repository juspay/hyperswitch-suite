# =============================================================================
# Identity
# =============================================================================

variable "compartment_id" {
  description = "OCID of the compartment the db system and all its supporting resources are created in. Replaces the implicit AWS account scope. This module does not create compartments - a flat compartment is the deliberate first-cut simplification."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, sandbox, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name, used in resource naming and freeform tags"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Informational for this module (the provider carries the region); used in descriptions and for the cross-region backup-copy sanity check."
  type        = string
}

variable "display_name" {
  description = "Display name of the db system. This is the cluster_identifier analogue and the value oci_monitoring_alarm selects on as resourceName. Defaults to '<environment>-<project_name>-pgsql'."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags merged over the module's own set. The tags_all analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). OCI has two tag namespaces where AWS has one; this one requires a tag namespace the module does not own, so it is passed straight through."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Engine
# =============================================================================

variable "db_version" {
  description = "PostgreSQL major version. OCI Database with PostgreSQL offers 14, 15, 16 and 17 only. PARTIAL (check sheet feature 20, section 4.13): there is no engine_lifecycle_support equivalent, so an end-of-life engine cannot be kept alive the way AWS's open-source-rds-extended-support does, and aws/live/prod/us-east-1's PG 13.23 is below the floor and cannot be ported as-is. Whether a MINOR version can be pinned here is open question 9.1 - if only majors are selectable the stack cannot hold a certified patch level."
  type        = string
  default     = "17"

  validation {
    condition     = contains(["14", "15", "16", "17"], var.db_version)
    error_message = "db_version must be one of 14, 15, 16, 17. OCI Database with PostgreSQL has no PG 13 and no extended-support lifecycle; a 13.x source cluster needs a major upgrade before it can be ported."
  }
}

variable "config_overrides" {
  description = "Engine parameter overrides, config_key -> value. The aws_rds_cluster_parameter_group analogue, collapsed from AWS's five custom_parameter_group_* variables into one map because OCI's override model is flat. NOT every PostgreSQL GUC may be put here: the service splits its variables into user variables (overridable) and system variables (not), and 118 of the 345 keys in the db-version-17 catalogue - including shared_preload_libraries, every ssl_* parameter and every archive_*/recovery_* parameter - are system variables that the API rejects with 400-InvalidParameter. The precondition in configuration.tf checks every key against the live catalogue at PLAN time; see the C10 banner there. NOTE (check sheet feature 14, section 4.11): there is no rds.force_ssl counterpart to put here - see var.tls_note. Extensions are enabled through the OCI-specific oci.admin_enabled_extensions key, NOT through shared_preload_libraries."
  type        = map(string)
  default     = {}
}

variable "config_override_extra_allowed_keys" {
  description = "Override keys permitted even though they do not appear in the service's default-configuration variable catalogue. OCI's own admin keys are not in that catalogue but ARE documented as valid dbConfigurationOverrides keys, so the catalogue alone is a necessary but not sufficient allowlist. Widening this is an explicit, reviewable act - it is the escape hatch for a key Oracle documents but does not publish in the catalogue, and it must not be used to smuggle in a key that is simply unverified. See the C10 banner in configuration.tf."
  type        = list(string)
  default     = ["oci.admin_enabled_extensions"]
}

variable "config_id" {
  description = "OCID of a pre-existing oci_psql_configuration to attach instead of letting this module create one. Ignored when config_overrides is non-empty."
  type        = string
  default     = null
}

variable "apply_config" {
  description = "How a configuration change is applied: RESTART or RELOAD."
  type        = string
  default     = "RESTART"

  validation {
    condition     = contains(["RESTART", "RELOAD"], var.apply_config)
    error_message = "apply_config must be RESTART or RELOAD."
  }
}

# =============================================================================
# Sizing
# =============================================================================
# PARTIAL (check sheet feature 2, section 4.1). Aurora lets every cluster
# instance carry its own class, AZ and promotion_tier; three live AWS roots
# exploit that (sandbox/ap-south-1 runs a db.r5.large writer beside a
# db.r5.xlarge reader). On OCI, shape / OCPU / memory are properties of the DB
# SYSTEM, so every node is identical, and there is no promotion_tier - the
# operator cannot nominate a failover winner. The AWS cluster_instances map is
# deliberately dropped rather than faked: size for the largest node the workload
# needs, or use a second db system for a genuinely different read shape.

# ONE input, TWO wire formats. This is the ListShapes `id` - the
# PostgreSQL.-prefixed string that oci_psql_db_system.shape takes.
# oci_psql_configuration.shape takes the same service record's un-prefixed
# `shape` field, and the module looks it up rather than deriving it. Do not add
# a second shape variable and do not pass the un-prefixed form here; see the C9
# banner in configuration.tf.
variable "shape" {
  description = "Compute shape applied to EVERY node, as a ListShapes `id` (PostgreSQL.-prefixed, e.g. PostgreSQL.VM.Standard.E5.Flex). There is no per-node shape on OCI. The un-prefixed form the engine configuration needs is resolved from the service, not from this string."
  type        = string
  default     = "PostgreSQL.VM.Standard.E5.Flex"
}

variable "instance_ocpu_count" {
  description = "OCPUs per node. Applies to every node - see the Sizing banner. Ignored by the engine configuration when var.shape is a flexible shape, where the service requires 0."
  type        = number
  default     = 2
}

variable "instance_memory_size_in_gbs" {
  description = "Memory per node in GB. Applies to every node. Ignored by the engine configuration when var.shape is a flexible shape, where the service requires 0."
  type        = number
  default     = 32
}

variable "instance_count" {
  description = "Number of nodes: one primary plus up to 7 read replicas. Default 2, NOT 1, and deliberately so - see the availability_domain variable and check sheet section 4.3. A single-node system drops the Oracle SLA from 99.99% / RTO < 2 min to 99.9% / RTO < 20 min."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 8
    error_message = "instance_count must be between 1 and 8 (one primary plus a maximum of 7 read replicas)."
  }
}

variable "instance_display_names" {
  description = "Optional per-node display names. instances_details carries only display_name / description / private_ip - it is NOT a per-node sizing or placement lever. Leave empty to let the service name the nodes."
  type        = list(string)
  default     = []
}

variable "state" {
  description = "ACTIVE or INACTIVE. INACTIVE stops the db system, which is the closest thing OCI has to Aurora Serverless v2 auto-pause and is worth using as a dev cost lever. It is NOT capacity autoscaling - see check sheet feature 23, section 4.15, verdict NONE: OCI has no ACU model, no auto-pause on idle, and no automatic capacity tracking. AWS's scaling_configuration and serverlessv2_scaling_configuration are dropped outright rather than modelled with a substitute."
  type        = string
  default     = "ACTIVE"

  validation {
    condition     = contains(["ACTIVE", "INACTIVE"], var.state)
    error_message = "state must be ACTIVE or INACTIVE."
  }
}

# =============================================================================
# Storage
# =============================================================================

variable "storage_system_type" {
  description = "Storage system type. OCI_OPTIMIZED_STORAGE auto-scales as tables are created and dropped (max 32 TB), which is the intent of AWS's storage_type = aurora-iopt1 with allocated_storage = null. Feeds BOTH oci_psql_db_system.system_type (CreateDbSystemDetails.systemType) and storage_details.system_type (the StorageDetails discriminator) - see the C14 audit note in main.tf for why they are one variable. DbSystemSystemTypeEnum has exactly one member, so this is effectively a constant."
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"

  validation {
    condition     = var.storage_system_type == "OCI_OPTIMIZED_STORAGE"
    error_message = "storage_system_type must be OCI_OPTIMIZED_STORAGE - the sole member of DbSystemSystemTypeEnum in provider 9.0.0 and OCI CLI 3.92.0, and the only StorageDetails arm the provider's mapToStorageDetails implements (anything else returns \"unknown system_type\" client-side). If Oracle adds a member, widen this and revisit both system_type fields together."
  }
}

variable "storage_iops" {
  description = "Provisioned IOPS. Tiers run 75k-750k; 375k and above requires 16 or more OCPUs. Leave null to take the service default for the shape."
  type        = number
  default     = null
}

variable "is_regionally_durable" {
  description = <<-EOT
    Data placement model for the block volume. NOT a durability level with a
    "more" and a "less" setting - it picks one of the service's two models:

      true  regional block volume;  "Nodes are placed in different availability
            domains." SUPPORTED ONLY IN 3-AD REGIONS.
      false AD-local block volume;  "Nodes are placed in different fault domains
            in the same availability domain."

    DEFAULT IS false, and that changed in C13. It was true, on the theory that
    true was "a no-op or better" in a single-AD region and kept the config
    portable. The first real create call in ap-mumbai-1 returned:

      400-InvalidParameter, Invalid isRegionallyDurable: isRegionallyDurable is
      set to true but either the region or the service doesn't support this
      feature. This feature is only supported in 3 AD regions. Please set the
      parameter as false and specify availabilityDomain.

    Not a no-op, not a silent downgrade - a hard rejection, and one that four
    clean plans and a passing `terraform validate` never saw, because it is a
    region property the provider schema cannot encode. false also matches the
    API's own documented default ("If not specified, it will be set to false").

    Setting this true is now guarded by a precondition in outputs.tf that reads
    the real availability-domain listing, so a wrong value fails at plan.

    In ap-mumbai-1 false costs nothing physical: with one AD, both models put a
    multi-node system in the same three fault domains of the same AD. What it
    costs is portability, and FORCE-NEW is why that matters - see section 4.3.
  EOT
  type        = bool
  default     = false
}

variable "availability_domain" {
  description = <<-EOT
    Availability domain to pin AD-local storage to. Mandatory when
    is_regionally_durable is false and forbidden when it is true; outputs.tf
    enforces both directions.

    LEAVE THIS NULL. Null does not mean "unset" - the module resolves index 0 of
    data.oci_identity_availability_domains, which in a single-AD region is the
    only entry. Passing it explicitly is the escape hatch for a multi-AD region
    that wants a specific AD, not the normal path, because an AD name carries a
    tenancy-specific opaque prefix ("Niou:AP-MUMBAI-1-AD-1" in this tenancy)
    that differs between tenancies. That prefix is the single fact that makes an
    AD name unsafe to write into a unit's inputs or a root.hcl local, and it is
    why six other OCI composition modules look it up the same way.

    PARTIAL (check sheet feature 5, section 4.3). READ THIS BEFORE ASSUMING HA.
    ap-mumbai-1 has exactly ONE availability domain - verified against the OCI
    regions page, and re-verified this session by a real
    `oci iam availability-domain list` against the dev compartment, which
    returned one entry. Only Frankfurt, London, Ashburn, Chicago and Phoenix
    have three. A multi-node db system in a single-AD region spreads its nodes
    "across all fault domains in the region, irrespective of whether an
    AD-specific or regional subnet" - that is three FAULT DOMAINS INSIDE ONE AD.
    A fault-domain spread is NOT AD-level fault tolerance and must not be
    mistaken for one: AWS ap-south-1 has three AZs and the live AWS unit pins
    instances to $${region}a and $${region}b, so an AZ loss is survivable by
    design. In ap-mumbai-1 an AD-scope failure IS a regional failure for this
    database, and the only layer below it is the DR path in
    docs/multi-cloud-parity/oci/data-tier-strategy.md.

    Check sheet open question 9.2 - "is is_regionally_durable = true accepted in
    ap-mumbai-1, and what does it do there?" - is CLOSED by C13, on the branch
    the question itself named: rejected outright, so the unit sets false plus a
    resolved AD. The question predicted the mechanic; only the apply could pick
    the branch.
  EOT
  type        = string
  default     = null
}

# =============================================================================
# Network
# =============================================================================

variable "subnet_id" {
  description = "OCID of the PRIVATE subnet the db system is placed in. Singular - OCI has no db-subnet-group analogue, so AWS's subnet_ids + create_db_subnet_group + db_subnet_group_name all collapse to this. FULL (check sheet feature 15): OCI Database with PostgreSQL endpoints are never directly reachable from the internet and there is no publicly_accessible toggle to get wrong, which is a stronger default than AWS."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN, required only when create_nsg is true (oci_core_network_security_group takes vcn_id). Not present in the check sheet's variable table - the provider requires it, so it is added rather than the NSG being hardcoded to a network."
  type        = string
  default     = null
}

variable "create_nsg" {
  description = "Create a module-owned, EMPTY network security group and attach the db system to it, exporting its OCID as nsg_id. Mirrors AWS create_security_group. The rules are written by the security-last phase unit, exactly as the AWS module leaves its security group ruleless."
  type        = bool
  default     = true
}

variable "nsg_ids" {
  description = "Additional NSG OCIDs to attach alongside the module-owned one."
  type        = list(string)
  default     = []
}

variable "primary_db_endpoint_private_ip" {
  description = "Optional fixed private IP for the primary endpoint. Leave null to let the service allocate."
  type        = string
  default     = null
}

variable "is_reader_endpoint_enabled" {
  description = "Enable the reader endpoint. PARTIAL (check sheet feature 4, section 4.2): it distributes connections evenly across replica nodes and falls back to the primary on a single-node system, but unlike Aurora's purely DNS-based reader endpoint it is CAPPED AT 8 Gbps AGGREGATE. A read-heavy workload tops out with no error, only latency. The instance_endpoints output is the escape hatch - client-side balancing across per-node endpoints bypasses the ceiling."
  type        = bool
  default     = true
}

# =============================================================================
# Credentials
# =============================================================================

variable "admin_username" {
  description = "Bootstrap admin username. Matches the AWS live roots' master_username."
  type        = string
  default     = "hyperswitch"
}

variable "admin_password" {
  description = "Admin password. Leave null to have the module generate one (random_password) - there is no manage_master_user_password on OCI, see check sheet section 4.10. Never set this to a literal in a unit; hand in a value only from a caller-owned secret store."
  type        = string
  default     = null
  sensitive   = true
}

variable "vault_secret" {
  description = "OCI Vault storage for the generated admin password. create = true writes the password to a new oci_vault_secret and wires the db system to it with password_type = VAULT_SECRET; otherwise the password is passed as PLAIN_TEXT (still generated, never a literal). key_id is required by oci_vault_secret and is not in the check sheet's variable table - the provider mandates it."
  type = object({
    create      = bool
    vault_id    = optional(string)
    key_id      = optional(string)
    secret_name = optional(string)
  })
  default = null
}

# =============================================================================
# Backup and point-in-time recovery
# =============================================================================
# PARTIAL (check sheet feature 9, section 4.7). AWS has ONE number:
# backup_retention_period = 7 is simultaneously the scheduled-backup retention
# AND the continuous PITR window. On OCI they are two independent policies, and
# translating backup_retention_period into retention_days alone ships a payments
# database with NO point-in-time recovery. Both are set here, and
# pitr_restore_days has no default so it cannot be forgotten.

variable "backup_kind" {
  description = "Backup schedule: DAILY, WEEKLY or MONTHLY."
  type        = string
  default     = "DAILY"

  validation {
    condition     = contains(["DAILY", "WEEKLY", "MONTHLY"], var.backup_kind)
    error_message = "backup_kind must be DAILY, WEEKLY or MONTHLY."
  }
}

variable "backup_start_hour" {
  description = <<-EOT
    Hour of day the backup starts, UTC, as a two-digit string "00".."23".

    THIS IS NOT THE WIRE FORMAT. The API field backupStart is a time of day,
    "HH:MM"; a bare hour is rejected with `400-InvalidParameter, Invalid
    backupStart 00` (C12). main.tf appends the ":00", so this variable stays
    hour-only and no caller can construct a malformed value. See the C12 banner
    above management_policy for the citations.

    HOUR GRANULARITY ONLY, and deliberately: every Oracle-authored example value
    is on the hour and every SDK doc string calls the field an hour, so minute
    precision is not claimed. AWS's preferred_backup_window = "00:51-01:21" has
    minute precision and becomes 00:00 here - 51 to 81 minutes earlier than the
    AWS window, not the "up to 9 minutes" this description claimed before C12.
  EOT
  type        = string
  default     = "00"

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])$", var.backup_start_hour))
    error_message = "backup_start_hour must be a two-digit hour string, 00 through 23."
  }
}

variable "backup_retention_days" {
  description = "Scheduled-backup retention. Automatic-backup retention tops out at 35 days. This is also what replaces AWS's final_snapshot_identifier: backups are 'stored after the database system deletion' for this many days."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 1 and 35 - OCI caps automatic-backup retention at 35 days."
  }
}

variable "backup_days_of_the_week" {
  description = "Days the backup runs when backup_kind = WEEKLY. Null for DAILY. MUST be non-empty when backup_kind = WEEKLY - daysOfTheWeek is mandatory:\"true\" on WeeklyBackupPolicy and a null one fails inside the provider's request marshaller, not at the API (C11, same class as odsp_insight_list). A precondition on oci_psql_db_system.this enforces it at plan time. Values are the FULL uppercase day names of WeeklyBackupPolicyDaysOfTheWeekEnum - SUNDAY, not SUN - which is the opposite of maintenance_window_start's three-letter day (C12)."
  type        = list(string)
  default     = null

  # C12 audit. The enum has exactly seven members and the SDK's
  # ValidateEnumValue rejects anything else client-side, which is the same
  # opaque non-HTTP failure class as C11's insight_type. Verified in
  # psql/weekly_backup_policy.go at provider v9.0.0, and in Oracle's own
  # acceptance test, which uses `SUNDAY`.
  validation {
    condition = var.backup_days_of_the_week == null || length(setsubtract(
      coalesce(var.backup_days_of_the_week, []),
      ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
    )) == 0
    error_message = "backup_days_of_the_week must contain only full uppercase day names - SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY. These are the seven members of WeeklyBackupPolicyDaysOfTheWeekEnum in provider 9.0.0; anything else is rejected by the SDK before the request is sent. Note this is NOT the three-letter form maintenance_window_start uses."
  }
}

variable "backup_days_of_the_month" {
  description = "Days the backup runs when backup_kind = MONTHLY. Null for DAILY. MUST be non-empty when backup_kind = MONTHLY - daysOfTheMonth is mandatory:\"true\" on MonthlyBackupPolicy, same failure mode as backup_days_of_the_week above. Capped at 28, not 31 (C12)."
  type        = list(number)
  default     = null

  # C12 audit. psql/monthly_backup_policy.go, and the provider's own markdown,
  # both state it verbatim: "To ensure that the backup runs monthly, the latest
  # day of the month that you can use to schedule a backup is the the 28th day."
  # 29, 30 and 31 do not exist in every month, so they are not schedulable.
  validation {
    condition = var.backup_days_of_the_month == null || alltrue([
      for d in coalesce(var.backup_days_of_the_month, []) : d >= 1 && d <= 28
    ])
    error_message = "backup_days_of_the_month entries must be 1-28. OCI caps the schedulable day at the 28th so that a monthly backup exists in every month."
  }
}

variable "backup_copy_regions" {
  description = "Regions to copy automatic backups into. This is the cheap half of the DR story and the ONLY DR mechanism that survives the warm-standby restore restriction, because it creates no replication relationship. A backup cannot be copied into the region it was created in. Empty disables copying."
  type        = list(string)
  default     = []
}

variable "pitr_restore_days" {
  description = "Point-in-time recovery window in days, to second granularity, restoring into a NEW db system. REQUIRED, no default: on AWS this window came free with backup_retention_period, and defaulting it here is how a database ships without PITR (check sheet section 4.7). Max 35. In-region only - PITR depends on the source db system existing, which a regional failure is exactly what removes."
  type        = number

  validation {
    condition     = var.pitr_restore_days >= 1 && var.pitr_restore_days <= 35
    error_message = "pitr_restore_days must be between 1 and 35."
  }
}

variable "maintenance_window_start" {
  description = <<-EOT
    Maintenance window start, UTC. The preferred_maintenance_window analogue.
    Null takes the service default, which is what every current root does - so
    the API has never seen a value from this module.

    FORMAT, verbatim from psql/management_policy_details.go at provider v9.0.0:

      The start of the maintenance window in UTC.
      This string is of the format: "{day-of-week} {time-of-day}".
      "{day-of-week}" is a case-insensitive string like "mon", "tue", &c.
      "{time-of-day}" is the "Time" portion of an RFC3339-formatted timestamp.
      Any second or sub-second time data will be truncated to zero.

    So "SUN 12:00" or "THU 15:00" - the two values Oracle itself uses, in
    internal/integrationtest/psql_db_system_test.go and examples/psql/main.tf
    respectively. This description gave 'SUNDAY 03:00' before C12, which is
    neither of the two forms Oracle demonstrates and is not what the SDK
    documents; nothing set it, so it never fired, and it is fixed here rather
    than on the first root that wants a maintenance window.

    THE TWO DAY FORMATS ON THIS RESOURCE ARE NOT THE SAME. This field takes the
    three-letter abbreviation; backup_days_of_the_week takes the full uppercase
    name from an enum (SUNDAY). Do not carry one into the other.
  EOT
  type        = string
  default     = null

  # C12 audit. Restricted to the abbreviation Oracle demonstrates, plus the
  # optional seconds the format spec permits (and truncates). Longer day names
  # may well work - the spec says "case-insensitive string like mon, tue", which
  # neither includes nor excludes them - but nothing verified says they do, and
  # a plan-time rejection naming the verified form is cheaper than a 400 several
  # minutes into a db-system create. Widen it with a citation if an apply proves
  # a longer form.
  validation {
    condition = var.maintenance_window_start == null || can(regex(
      "^(?i:mon|tue|wed|thu|fri|sat|sun) ([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$",
      coalesce(var.maintenance_window_start, "")
    ))
    error_message = "maintenance_window_start must be \"{day-of-week} {time-of-day}\", e.g. \"SUN 12:00\" or \"THU 15:00\" - a three-letter day abbreviation, a space, and an RFC3339 time portion. Full day names like \"SUNDAY\" are not among the forms Oracle demonstrates for this field; backup_days_of_the_week is the one that takes SUNDAY."
  }
}

variable "on_demand_backup" {
  description = "Create a named on-demand oci_psql_backup. This is the closest analogue of AWS's final_snapshot_identifier / skip_final_snapshot pair, since a manually created backup can be retained independently of the db system's own policy. Null to skip."
  type = object({
    display_name     = string
    description      = optional(string)
    retention_period = optional(number)
  })
  default = null
}

# =============================================================================
# Cross-region DR - Replication with Warm Standby (SUBSTITUTE)
# =============================================================================
# See the DR banner in locals.tf. Replaces AWS's seven global-cluster variables
# (create_global_cluster, global_cluster_identifier, global_deletion_protection,
# enable_global_write_forwarding, use_existing_as_global_primary,
# source_db_cluster_identifier, replication_source_identifier + source_region)
# with one OCID and an RPO pair, because there is no global object to name.

variable "enable_warm_standby" {
  description = <<-EOT
    Make THIS db system a warm standby of another region's db system. DEFAULT
    FALSE, and off for the dev cut by decision, not by omission.

    The tradeoff being declined by leaving it false, stated once here so it is
    never silently baked in:
      RPO   - 300 s floor (default 300, max 10800) versus Aurora Global
              Database's 20 s enforceable floor and sub-second observed lag.
              15x wider at best.
      Mode  - manual failover only. "Automatic failover isn't supported." RTO
              goes from Aurora's "less than 1 minute" to human-paged minutes.
      Bound - is_rpo_enforced = true bounds the loss but puts the PRIMARY into
              read-only mode when lag exceeds the threshold, i.e. the DR feature
              can cause a payments outage. false leaves the window unbounded.
      Cost  - a second full db system, running continuously, at a comparable
              shape.
      Restore - forfeited entirely while this is true (section 4.8).

    Requires PG >= 14 on both ends. Enforced in outputs.tf.
  EOT
  type        = bool
  default     = false
}

variable "primary_db_system_id" {
  description = "OCID of the primary db system this one replicates from. Set together with enable_warm_standby. Replaces AWS's global_cluster_id + cluster_arn pair with a single identifier - there is no global cluster to join, only a primary to point at."
  type        = string
  default     = null
}

variable "is_rpo_enforced" {
  description = "Enforce rpo_in_seconds. True bounds the data-loss window by switching the PRIMARY to read-only when replication lag exceeds it; false lets the system keep serving writes with an unbounded window. Binary, with no middle setting - this is a business decision, not an infrastructure one."
  type        = bool
  default     = true
}

variable "rpo_in_seconds" {
  description = "Replication RPO threshold. Minimum 300, maximum 10800, default 300. The 300 is a THRESHOLD, not a measurement: no steady-state lag figure is published for warm standby (GA 2026-06-16), so the real RPO is unknown until the Replication Lag metric in namespace oci_postgresql has been observed under representative write volume."
  type        = number
  default     = 300

  validation {
    condition     = var.rpo_in_seconds >= 300 && var.rpo_in_seconds <= 10800
    error_message = "rpo_in_seconds must be between 300 and 10800. There is no OCI setting that gives Aurora's sub-second RPO; 300 is the floor."
  }
}

variable "apply_change_mode_to_stand_alone" {
  description = "Promotion mode used when a standby is converted to standalone (drop primary_db_system_id and set this). REPLAY_PENDING_UPDATES applies all received WAL first and is the default; IMMEDIATELY discards unapplied WAL and therefore loses MORE than the configured RPO by an unknown amount - use it only when the primary region is confirmed gone. Note the step the runbook forgets: after promotion the old primary remains a standalone system and must be explicitly re-pointed, or the platform runs with no DR."
  type        = string
  default     = null

  validation {
    condition     = var.apply_change_mode_to_stand_alone == null || contains(["REPLAY_PENDING_UPDATES", "IMMEDIATELY"], coalesce(var.apply_change_mode_to_stand_alone, "REPLAY_PENDING_UPDATES"))
    error_message = "apply_change_mode_to_stand_alone must be REPLAY_PENDING_UPDATES or IMMEDIATELY."
  }
}

# =============================================================================
# Restore
# =============================================================================

variable "source_backup_id" {
  description = "Create this db system from an existing backup. Replaces AWS's snapshot_identifier (aws/live/prod/eu-west-1 really did use it). Mutually exclusive with enable_warm_standby - see check sheet section 4.8."
  type        = string
  default     = null
}

variable "source_pitr" {
  description = "Create this db system by point-in-time restore of another one. Replaces AWS's restore_to_point_in_time block. time_to_restore is RFC3339. Mutually exclusive with enable_warm_standby and with source_backup_id."
  type = object({
    db_system_id                       = string
    time_to_restore                    = string
    is_having_restore_config_overrides = optional(bool)
  })
  default = null
}

# =============================================================================
# Observability
# =============================================================================

variable "query_insights_enabled" {
  description = "Enable Query Insights - the Performance Insights analogue (GA 2026-06-16). Replaces AWS's four performance_insights_* and two monitoring_* variables. Retention is 7 days, the only value the service supports, which happens to match the live performance_insights_retention_period = 7. It is NOT defaulted server-side despite the docs saying so - see query_insight_types and the C14 banner in main.tf."
  type        = bool
  default     = true
}

variable "query_insight_types" {
  description = <<-EOT
    odsp_insight_list entries for oci_psql_db_system. MUST be non-empty whenever
    query_insights_enabled is true - odspInsightList is mandatory when
    odsp_insight_details.kind = ENABLED, and an empty list fails inside the
    provider's request marshaller rather than at the API (C11; see the banner
    above odsp_insight_details in main.tf for the mechanism and citations).

    insight_type must be a member of OdspInsightInsightTypeEnum, which has
    exactly one: QUERY_INSIGHT. Verified in the Go SDK vendored in provider
    9.0.0 (psql/odsp_insight.go) and in OCI CLI 3.92.0's Python SDK
    (INSIGHT_TYPE_QUERY_INSIGHT). Both preconditions on oci_psql_db_system.this
    enforce this at plan time.

    retention_period_in_days MUST carry a concrete number. C14: the API rejects
    its absence at create time -

      400-InvalidParameter, Invalid odspInsightDetails: retentionPeriodInDays
      'null' is invalid

    - even though every Oracle artefact says it is optional and has a server
    default of 7. The Go SDK tags it mandatory:"false", the CLI's Python SDK
    does not mark it [Required], the provider docs call it "(Applicable when
    kind=ENABLED)" rather than "(Required when ...)", and all of them state
    "Current supported value is 7 days. the system default is 7 days". Four
    artefacts, all wrong; the documented default does not exist on the create
    path. See the C14 banner above odsp_insight_details in main.tf.

    The type therefore declares optional(number, 7) rather than optional(number).
    A caller who omits the attribute AND a caller who passes an explicit null
    both get 7, because Terraform applies an optional() default to a null value
    (verified with terraform 1.14 this session) - which makes the null state
    UNREACHABLE rather than merely guarded, the same outcome C12 achieved for
    backup_start. 7 also matches the live AWS
    performance_insights_retention_period = 7.

    The VALUE is still guarded, because a caller can pass a wrong number: a
    precondition on oci_psql_db_system.this rejects anything outside
    local.query_insight_retention_days_supported, which is [7] - the sole
    supported value in provider 9.0.0, OCI CLI 3.92.0 and Oracle's Query
    Insights documentation ("retains ... for a maximum of seven days"). If
    Oracle widens the range, that local is the one literal to edit.
  EOT
  type = list(object({
    insight_type             = string
    retention_period_in_days = optional(number, 7)
  }))
  default = [{ insight_type = "QUERY_INSIGHT", retention_period_in_days = 7 }]
}

variable "enable_service_logs" {
  description = "Ship engine logs to OCI Logging (service postgresql, category postgresql_database_logs). FULL (check sheet feature 17) as a capability, but configured on separate resources instead of AWS's enabled_cloudwatch_logs_exports argument. Whether the log CONTENT matches AWS's postgresql export is check sheet open question 9.6 and is unverified - if it differs, vector/loki parsing rules change."
  type        = bool
  default     = true
}

variable "log_retention_duration" {
  description = "OCI Logging retention in days for the engine log."
  type        = number
  default     = 30
}

# =============================================================================
# Protection
# =============================================================================

variable "prevent_destroy" {
  description = <<-EOT
    Declared teardown protection. NONE (check sheet feature 19, section 4.12).

    THE GAP: oci_psql_db_system has NO deletion_protection field. Not renamed,
    not nested - it does not exist anywhere in provider 9.0.0's schema for this
    resource (verified this session by dumping the provider's own JSON schema).
    All seven AWS live roots set deletion_protection = true on the cluster and
    global_deletion_protection = true on the global cluster; none of that can be
    reproduced. There is no service-side veto on deleting the payments database.
    That matters more than it sounds, because the force-new set is not small:
    db_version, storage_details.system_type, storage_details.availability_domain
    and network_details.subnet_id are all non-updatable, so an innocuous-looking
    edit can plan a replace.

    HOW THIS VARIABLE BEHAVES: Terraform forbids a variable in
    lifecycle.prevent_destroy ("Variables may not be used here" - verified with
    terraform 1.14 this session), so this flag cannot switch the lifecycle block
    on and off. The block is therefore hardcoded true on oci_psql_db_system, and
    this variable is a declared-intent flag: setting it false does NOT weaken
    the guard, it raises a precondition that tells the operator the real
    teardown procedure. Mitigation layers (b) and (c) from section 4.12 -
    backup retention_days surviving deletion, and an IAM policy denying the
    delete verb on postgres-db-systems outside a break-glass group - are the
    only controls that survive a wrong terraform apply, and layer (c) is
    outside this module.
  EOT
  type        = bool
  default     = true
}
