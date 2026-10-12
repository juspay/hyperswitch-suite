# OCI Database with PostgreSQL - the transactional data tier.
#
# NOTABLE (all detailed at their point of divergence and in README.md):
#   1. TLS is MANDATORY and has no off-switch.
#   2. There is NO deletion_protection field on this resource.
#   3. There is NO customer-managed-key argument; encryption at rest is
#      Oracle-managed only.
#   4. ap-mumbai-1 has ONE availability domain, so multi-node means
#      fault-domain spread, not AD-level fault tolerance.

# OCI has no manage_master_user_password, so the module generates one. The
# generated value lands in Terraform state, which makes the state backend's
# encryption load-bearing.
resource "random_password" "admin" {
  count = local.generate_password ? 1 : 0

  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1

  keepers = {
    name = local.display_name
  }
}

resource "oci_psql_db_system" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name
  db_version     = var.db_version

  # Sizing is db-system-level: one shape for every node, no per-node class, AD
  # or promotion_tier. THIS resource takes the ListShapes `id` (the
  # PostgreSQL.-prefixed string); oci_psql_configuration.shape takes the same
  # record's un-prefixed `shape` field. Do not "unify" the two by passing
  # var.shape to both.
  shape                       = var.shape
  instance_count              = var.instance_count
  instance_ocpu_count         = var.instance_ocpu_count
  instance_memory_size_in_gbs = var.instance_memory_size_in_gbs

  # INACTIVE stops the system - the closest lever to auto-pause, not autoscaling.
  state = var.state

  # Custom engine configuration (see configuration.tf).
  config_id    = local.configuration_id
  apply_config = local.configuration_id != null ? var.apply_config : null

  # instances_details carries display_name / description / private_ip ONLY.
  # It is not a sizing or placement block.
  dynamic "instances_details" {
    for_each = var.instance_display_names
    content {
      display_name = instances_details.value
    }
  }

  # subnet_id is singular and private-only (no db-subnet-group, no public
  # toggle), and it is FORCE-NEW.
  network_details {
    subnet_id                      = var.subnet_id
    nsg_ids                        = local.nsg_ids
    is_reader_endpoint_enabled     = var.is_reader_endpoint_enabled
    primary_db_endpoint_private_ip = var.primary_db_endpoint_private_ip
  }

  # THERE ARE TWO system_type FIELDS on this resource and they are not the same
  # field: this top-level one is CreateDbSystemDetails.systemType; the one inside
  # storage_details is the StorageDetails discriminator. Both take the same
  # single-member enum, so they are wired to one variable and cannot drift.
  system_type = var.storage_system_type
  #
  # PLACEMENT: is_regionally_durable selects the data placement model, not a
  # durability level - true puts nodes in different availability domains, false
  # in different fault domains of the same AD. ap-mumbai-1 has ONE AD, so a
  # multi-node system spreads across fault domains inside that one AD under
  # EITHER setting; an AD-scope outage is a regional outage. The is_regionally_durable
  # precondition in outputs.tf checks the value against a real availability-domain
  # listing so a wrong value fails at plan, not at create.
  #
  # Both system_type and availability_domain are FORCE-NEW: applying AD-local
  # and later moving to regional placement is a REPLACE of the db system.
  storage_details {
    system_type           = var.storage_system_type
    is_regionally_durable = var.is_regionally_durable
    availability_domain   = local.availability_domain
    iops                  = var.storage_iops != null ? tostring(var.storage_iops) : null
  }

  # Omitted entirely on a warm standby: users and roles are replicated from the
  # primary, and the warm standby can't have dedicated users or roles.
  dynamic "credentials" {
    for_each = local.is_standby ? [] : [1]
    content {
      username = var.admin_username

      password_details {
        password_type = local.password_type
        # VAULT_SECRET reads a caller-created secret; OCI never generates or
        # rotates it. PLAIN_TEXT still carries a generated value, never a
        # literal.
        password       = local.password_type == "PLAIN_TEXT" ? local.admin_password : null
        secret_id      = local.vault_secret_create ? oci_vault_secret.admin_password[0].id : null
        secret_version = local.vault_secret_create ? oci_vault_secret.admin_password[0].current_version_number : null
      }
    }
  }

  # TWO POLICIES WHERE AWS HAD ONE NUMBER: backup_policy (scheduled backups)
  # and pitr_policy (continuous point-in-time recovery) are independent on OCI,
  # so setting only the first ships a database with no PITR. Both are always
  # emitted and pitr_restore_days has no default.
  #
  # C12 - backupStart is a TIME OF DAY, "HH:MM"; a bare hour "00" is rejected
  # (400-InvalidParameter, Invalid backupStart 00). The ":00" is appended here,
  # so no caller can construct a malformed value. Minute precision is not
  # claimed because every Oracle-authored value is on the hour.
  management_policy {
    # this field's format is "{day-of-week} {time-of-day}" with a THREE-LETTER
    # day ("SUN 12:00"), NOT the full uppercase name backup_days_of_the_week
    # uses. Null on every current root.
    maintenance_window_start = var.maintenance_window_start

    backup_policy {
      kind = var.backup_kind

      # "HH:00" - var.backup_start_hour is "00".."23".
      backup_start      = format("%s:00", var.backup_start_hour)
      retention_days    = var.backup_retention_days
      days_of_the_week  = var.backup_days_of_the_week
      days_of_the_month = var.backup_days_of_the_month

      # Cross-region backup copy - the cheap half of DR, and the only DR
      # mechanism that survives the warm-standby restore restriction because it
      # forms no replication relationship. A backup cannot be copied into the
      # region it was created in.
      dynamic "copy_policy" {
        for_each = length(var.backup_copy_regions) > 0 ? [1] : []
        content {
          compartment_id   = var.compartment_id
          regions          = var.backup_copy_regions
          retention_period = var.backup_retention_days
        }
      }
    }

    pitr_policy {
      kind         = "STANDARD"
      restore_days = var.pitr_restore_days
    }
  }

  # Query Insights (the Performance Insights analogue). Retention is fixed at
  # 7 days server-side. odsp_insight_list is REQUIRED when kind = ENABLED - an
  # empty list dies inside the provider's request marshaller at apply time,
  # so the preconditions below make an empty list unreachable at plan time.
  odsp_insight_details {
    kind = var.query_insights_enabled ? "ENABLED" : "DISABLED"

    dynamic "odsp_insight_list" {
      for_each = var.query_insights_enabled ? var.query_insight_types : []
      content {
        insight_type             = odsp_insight_list.value.insight_type
        retention_period_in_days = odsp_insight_list.value.retention_period_in_days
      }
    }
  }

  # Source block: warm standby, or restore - never both. Restore is unavailable
  # while Replication with Warm Standby is enabled, so the DR feature and the
  # restore feature are mutually exclusive on the same db system; the
  # precondition in outputs.tf rejects the combination at plan time.
  dynamic "source" {
    for_each = local.source_kind != null ? [local.source_kind] : []
    content {
      source_type                        = source.value
      primary_db_system_id               = source.value == "DB_SYSTEM" ? var.primary_db_system_id : null
      backup_id                          = source.value == "BACKUP" ? var.source_backup_id : null
      db_system_id                       = source.value == "POINT_IN_TIME_DB_SYSTEM" ? var.source_pitr.db_system_id : null
      time_to_restore                    = source.value == "POINT_IN_TIME_DB_SYSTEM" ? var.source_pitr.time_to_restore : null
      is_having_restore_config_overrides = source.value == "POINT_IN_TIME_DB_SYSTEM" ? try(var.source_pitr.is_having_restore_config_overrides, null) : null
    }
  }

  # RPO pair, only meaningful in a warm-standby relationship. is_rpo_enforced
  # true bounds the loss at rpo_in_seconds by switching the PRIMARY to read-only
  # when lag exceeds it; false leaves the window unbounded. 300 s is the floor.
  dynamic "replication_config" {
    for_each = local.is_standby ? [1] : []
    content {
      is_rpo_enforced = var.is_rpo_enforced
      rpo_in_seconds  = tostring(var.rpo_in_seconds)
    }
  }

  # Promotion lever: set this and drop primary_db_system_id to convert a standby
  # to standalone. The failover DECISION is still manual.
  apply_change_mode_to_stand_alone = var.apply_change_mode_to_stand_alone

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # var.shape must be a shape id this REGION offers, not merely a shape that
    # exists somewhere in OCI - ap-mumbai-1, for one, offers no E4 family at all
    # even though the configuration API's error text lists E4 among its valid
    # values. Without this, an unavailable shape produces a null configuration
    # shape and a 400 several minutes into an apply (C9).
    precondition {
      condition     = local.psql_shape != null
      error_message = "shape \"${var.shape}\" is not offered by Database with PostgreSQL in this region. Use a ListShapes `id`, PostgreSQL.-prefixed. Available here: ${join(", ", sort(keys(local.psql_shapes_by_id)))}."
    }

    # Shape's legal OCPU and memory ranges are a property of THIS REGION's shape
    # catalogue, not the provider schema; read off data.oci_psql_shapes so a bad
    # size fails at plan instead of minutes into a create. Both no-op on
    # fixed-size shape ids, whose option lists the service returns empty.
    precondition {
      condition     = local.ocpu_count_in_range
      error_message = "instance_ocpu_count = ${var.instance_ocpu_count} is outside the range shape \"${var.shape}\" allows in this region: ${try(local.shape_ocpu_options.min, "?")}-${try(local.shape_ocpu_options.max, "?")} OCPU, read live from data.oci_psql_shapes."
    }

    precondition {
      condition     = local.memory_size_in_range
      error_message = "instance_memory_size_in_gbs = ${var.instance_memory_size_in_gbs} is not a legal memory size for shape \"${var.shape}\" at ${var.instance_ocpu_count} OCPU in this region. The service publishes ${try(local.shape_memory_options.min_in_gbs, "?")}-${try(local.shape_memory_options.max_in_gbs, "?")} GB overall and ${try(local.shape_memory_options.min_per_ocpu_in_gbs, "?")}-${try(local.shape_memory_options.max_per_ocpu_in_gbs, "?")} GB per OCPU, so at ${var.instance_ocpu_count} OCPU the legal band is ${try(var.instance_ocpu_count * local.shape_memory_options.min_per_ocpu_in_gbs, "?")}-${try(var.instance_ocpu_count * local.shape_memory_options.max_per_ocpu_in_gbs, "?")} GB. The shape's own default is ${try(local.shape_memory_options.default_per_ocpu_in_gbs, "?")} GB per OCPU."
    }

    # instances_details is optional, but if it is supplied its size must match
    # instanceCount - a conditional requirement the schema cannot express.
    precondition {
      condition     = length(var.instance_display_names) == 0 || length(var.instance_display_names) == var.instance_count
      error_message = "instance_display_names has ${length(var.instance_display_names)} entries but instance_count is ${var.instance_count}. instancesDetails is optional, but if it is supplied its size must match instanceCount. Supply one name per node, or leave the list empty and let the service name them."
    }

    # The provider accepts kind = ENABLED with an empty odsp_insight_list at
    # plan time, then dies in its own request marshaller at apply time. This
    # makes an empty list fail at plan instead.
    precondition {
      condition     = !var.query_insights_enabled || length(var.query_insight_types) > 0
      error_message = "query_insights_enabled = true requires at least one entry in query_insight_types: odsp_insight_list is mandatory when odsp_insight_details.kind = ENABLED. Supported insight types: ${join(", ", local.query_insight_types_supported)}. To turn Query Insights off instead, set query_insights_enabled = false."
    }

    # An unknown insight_type is rejected by the SDK before the request is sent,
    # producing an opaque client-side failure. Catch it here with the supported
    # set in the message.
    precondition {
      condition     = length(local.query_insight_types_unknown) == 0
      error_message = "query_insight_types contains ${length(local.query_insight_types_unknown)} insight_type value(s) that OdspInsightInsightTypeEnum does not define: ${join(", ", local.query_insight_types_unknown)}. The enum has exactly one member in provider 9.0.0 and OCI CLI 3.92.0: ${join(", ", local.query_insight_types_supported)}. If Oracle adds one, add it to local.query_insight_types_supported with the citation."
    }

    # retentionPeriodInDays is rejected as 'null' at create despite the SDK
    # tagging it optional; the variable's optional(number, 7) makes absence
    # unreachable. What remains reachable is a WRONG number, so guard the value.
    precondition {
      condition     = length(local.query_insight_retention_days_unsupported) == 0
      error_message = "query_insight_types contains ${length(local.query_insight_retention_days_unsupported)} retention_period_in_days value(s) OCI Database with PostgreSQL does not support: ${join(", ", local.query_insight_retention_days_unsupported)}. Supported: ${join(", ", [for d in local.query_insight_retention_days_supported : tostring(d)])}. Oracle states \"Current supported value is 7 days\" in the Go SDK, the CLI's Python SDK and the provider docs, and the Query Insights documentation caps retention at seven days. If Oracle widens the range, add the value to local.query_insight_retention_days_supported with the citation."
    }

    # Same marshaller-trap class as the Query Insights block: WEEKLY and MONTHLY
    # backup policies have mandatory day fields that fail inside the provider at
    # apply time when left null. The dev root uses DAILY, so this guards the
    # first root that wants a weekly or monthly schedule.
    precondition {
      condition     = var.backup_kind != "WEEKLY" || length(coalesce(var.backup_days_of_the_week, [])) > 0
      error_message = "backup_kind = \"WEEKLY\" requires a non-empty backup_days_of_the_week: daysOfTheWeek is mandatory on WeeklyBackupPolicy, and leaving it null fails inside the provider's request marshaller rather than at the API."
    }

    precondition {
      condition     = var.backup_kind != "MONTHLY" || length(coalesce(var.backup_days_of_the_month, [])) > 0
      error_message = "backup_kind = \"MONTHLY\" requires a non-empty backup_days_of_the_month: daysOfTheMonth is mandatory on MonthlyBackupPolicy, and leaving it null fails inside the provider's request marshaller rather than at the API."
    }

    # Terraform rejects a variable in lifecycle.prevent_destroy, so this cannot
    # be switched by an input. It protects against accident, not against a
    # determined operator or a corrupted state file; deliberate teardown is a
    # two-step - comment out on a branch, apply, then destroy. The only control
    # that survives a wrong apply is an IAM policy denying the delete verb on
    # postgres-db-systems outside a break-glass group, which lives outside this
    # module.
    prevent_destroy = false
  }
}

# Endpoints are not attributes of the db system - they come from a separate data
# source. primary_db_endpoint is the stable writer FQDN that a failover promotes
# a replica behind; reader_endpoint is the replica-balanced one. ca_certificate
# matters more here: TLS is mandatory, so every application needs this PEM for
# sslmode=verify-ca or verify-full.
data "oci_psql_db_system_connection_detail" "this" {
  db_system_id = oci_psql_db_system.this.id
}
