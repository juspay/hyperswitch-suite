# The card vault's OWN database: a DEDICATED PostgreSQL db system rather than
# the shared platform database, so the cardholder-data blast radius stays inside
# one module and one PCI-DSS scope boundary.
#
# THE SHAPE: there is no compute tier and no load balancer here - the card-vault
# binary runs as an OKE workload. This is an oracle-gate decision and the gate
# has not been convened.
#
# WHY THIS CREATES oci_psql_db_system DIRECTLY instead of nesting
# composition/database: this module needs about a fifth of that resource surface,
# and the dedicated database must not inherit the sibling's weaker credential
# path (random_password lands in state); OCI Vault generates the password here
# so no credential ever exists as a Terraform value. The cost is duplication - a
# fix to oci_psql_db_system usage there does not reach here.
#
# FOUR THINGS ABOUT OCI DATABASE WITH POSTGRESQL A READER WILL OTHERWISE GET
# WRONG (confirmed against provider 9.0.0, identical to composition/database):
#   1. TLS is MANDATORY with no off-switch.
#   2. There is NO deletion_protection field.
#   3. There is NO customer-managed-key argument; encryption at rest is
#      Oracle-managed only.
#   4. ap-mumbai-1 has ONE availability domain, so multi-node means fault-domain
#      spread, not AD-level fault tolerance.

resource "oci_psql_db_system" "locker" {
  count = var.create_database ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.db_display_name
  description    = "Dedicated PostgreSQL database for the ${var.environment} card vault (PCI-DSS scope). Managed by composition/locker."
  db_version     = var.database_config.db_version

  # Sizing is db-system-level: one shape for every node; no per-node class, AD
  # or promotion_tier.
  shape                       = var.database_config.shape
  instance_count              = var.database_config.instance_count
  instance_ocpu_count         = var.database_config.instance_ocpu_count
  instance_memory_size_in_gbs = var.database_config.instance_memory_size_in_gbs

  # Custom engine configuration (see configuration.tf).
  config_id    = local.db_configuration_id
  apply_config = local.db_configuration_id != null ? var.database_config.apply_config : null

  # subnet_id is singular, private-only and FORCE-NEW. The intended subnet is
  # vpc-network's `locker-database` tier, whose route table carries NO gateway
  # routes - the strongest isolation the VCN offers. The database is a member
  # of the NSG that security-rules writes into.
  network_details {
    subnet_id                      = var.subnet_id
    nsg_ids                        = local.db_nsg_ids
    is_reader_endpoint_enabled     = var.database_config.is_reader_endpoint_enabled
    primary_db_endpoint_private_ip = var.database_config.primary_db_endpoint_private_ip
  }

  # THE GAP: there is no customer-managed-key argument on oci_psql_db_system or
  # oci_psql_configuration in provider 9.0.0. The data IS encrypted at rest,
  # but under an Oracle-managed key this tenancy cannot rotate, scope or revoke.
  # The vault/key in kms.tf protect the CREDENTIAL, not the database's storage -
  # the single most consequential loss for a PCI-DSS component, needing explicit
  # sign-off. is_regionally_durable is FORCE-NEW; the provider forbids setting
  # availability_domain alongside it.
  storage_details {
    system_type           = var.database_config.storage_system_type
    is_regionally_durable = var.database_config.is_regionally_durable
    availability_domain   = var.database_config.is_regionally_durable ? null : var.database_config.availability_domain
    iops                  = var.database_config.storage_iops != null ? tostring(var.database_config.storage_iops) : null
  }

  # password_type is hardcoded VAULT_SECRET, by construction - a PLAIN_TEXT
  # password would be a Terraform value ending up in state, which this module
  # exists to avoid. Omitted entirely on a warm standby, which inherits the
  # primary's users.
  dynamic "credentials" {
    for_each = local.is_standby ? [] : [1]
    content {
      username = var.database_config.admin_username

      password_details {
        password_type  = "VAULT_SECRET"
        secret_id      = local.db_secret_id
        secret_version = local.db_secret_version
      }
    }
  }

  # TWO POLICIES WHERE AWS HAD ONE NUMBER: backup_policy (scheduled backups)
  # and pitr_policy (continuous PITR) are independent on OCI, so setting only
  # the first ships the card vault's database with no point-in-time recovery.
  # C12 - backupStart is a TIME OF DAY, "HH:MM"; a bare hour is rejected, so
  # the ":00" is appended here.
  management_policy {
    maintenance_window_start = var.database_config.maintenance_window_start

    backup_policy {
      kind              = var.database_config.backup_kind
      backup_start      = format("%s:00", var.database_config.backup_start_hour)
      retention_days    = var.database_config.backup_retention_days
      days_of_the_week  = var.database_config.backup_days_of_the_week
      days_of_the_month = var.database_config.backup_days_of_the_month

      # Cross-region backup copy: the cheap half of DR, and the only DR
      # mechanism that survives the warm-standby restore restriction because it
      # forms no replication relationship. A backup cannot be copied into the
      # region it was created in.
      dynamic "copy_policy" {
        for_each = length(var.database_config.backup_copy_regions) > 0 ? [1] : []
        content {
          compartment_id   = var.compartment_id
          regions          = var.database_config.backup_copy_regions
          retention_period = var.database_config.backup_retention_days
        }
      }
    }

    pitr_policy {
      kind         = "STANDARD"
      restore_days = var.database_config.pitr_restore_days
    }
  }

  # Query Insights (the Performance Insights analogue). Retention is fixed at
  # 7 days server-side.
  odsp_insight_details {
    kind = var.database_config.query_insights_enabled ? "ENABLED" : "DISABLED"
  }

  # Multi-region DR via Replication with Warm Standby, OFF by default - that is
  # a decision. Turning it on, for the CARD VAULT specifically:
  #   - RPO floor is 300 s (manual failover; up to five minutes of committed
  #     card data on an unplanned regional failure).
  #   - is_rpo_enforced = true bounds the loss but switches the PRIMARY to
  #     read-only when lag exceeds the threshold; false leaves it unbounded.
  #   - A second full db system is needed, and because the vault's database is
  #     dedicated a passive-region locker needs its own warm-standby pair on top
  #     of the shared database's, doubling the DR footprint.
  #   - Restore is forfeited entirely while it is on.
  # A wider RPO on cardholder-data infrastructure is materially different risk
  # from the shared database's and should be sized/signed off separately.
  dynamic "source" {
    for_each = local.is_standby ? [1] : []
    content {
      source_type          = "DB_SYSTEM"
      primary_db_system_id = var.database_config.primary_db_system_id
    }
  }

  dynamic "replication_config" {
    for_each = local.is_standby ? [1] : []
    content {
      is_rpo_enforced = var.database_config.is_rpo_enforced
      rpo_in_seconds  = tostring(var.database_config.rpo_in_seconds)
    }
  }

  # Promotion lever: set this and drop primary_db_system_id to convert a
  # standby to standalone. The failover DECISION is still manual.
  apply_change_mode_to_stand_alone = var.database_config.apply_change_mode_to_stand_alone

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    # HARDCODED true because Terraform rejects a variable in a lifecycle block.
    # It is the ONLY Terraform-level guard, since oci_psql_db_system has no
    # deletion_protection argument; a strictly weaker class of control than AWS's
    # service-enforced flag, which matters more for the card vault's database.
    # Deliberate teardown is a two-step - comment out on a branch, apply, then
    # destroy. The only control that survives a wrong apply is an IAM policy
    # denying the delete verb on postgres-db-systems outside a break-glass
    # group, still outstanding.
    prevent_destroy = true

    precondition {
      condition     = local.is_standby == (var.database_config.primary_db_system_id != null)
      error_message = "database_config.enable_warm_standby and .primary_db_system_id must be set together. Warm standby is OFF by default and that default is a decision - 300 s RPO floor, manual-only failover, a second full db system, and restore forfeited. See docs/multi-cloud-parity/oci/data-tier-strategy.md and locker.md section 4.4 before turning it on."
    }

    precondition {
      condition     = local.is_standby || local.db_secret_id != null
      error_message = "A standalone locker database needs a credential. Either leave db_admin_secret.create = true so OCI Vault generates the password server-side, or supply db_admin_secret.secret_id + .secret_version for a secret you already own. This module has no plaintext-password input by design - see secrets.tf."
    }

    precondition {
      condition     = !var.database_config.is_regionally_durable || var.database_config.availability_domain == null
      error_message = "database_config.availability_domain cannot be set when is_regionally_durable = true - the provider forbids the pair. In a single-AD region such as ap-mumbai-1 keep is_regionally_durable = true and leave availability_domain null; the nodes still spread across fault domains, which is NOT AD-level fault tolerance."
    }

    precondition {
      condition     = var.database_config.is_regionally_durable || var.database_config.availability_domain != null
      error_message = "database_config.availability_domain is required when is_regionally_durable = false."
    }
  }
}

# Endpoints are not attributes of the db system - they come from a separate data
# source. primary_db_endpoint is the stable writer FQDN that a failover promotes
# a replica behind; reader_endpoint is the replica-balanced one. ca_certificate
# matters most here: TLS is mandatory, so the card-vault app needs this PEM for
# sslmode=verify-ca or verify-full.
data "oci_psql_db_system_connection_detail" "locker" {
  count = var.create_database ? 1 : 0

  db_system_id = oci_psql_db_system.locker[0].id
}
