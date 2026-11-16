# =============================================================================
# The card vault's OWN database (check sheet feature 15, FULL)
# =============================================================================
# The defining property of the AWS locker module: it provisions a DEDICATED
# Aurora PostgreSQL cluster rather than sharing the platform database, so the
# cardholder-data blast radius stays inside one module and one PCI-DSS scope
# boundary. `create_locker_database` is true in every real instantiation seen.
# GCP kept the property (its own AlloyDB cluster). This module keeps it too.
#
# -----------------------------------------------------------------------------
# THE SHAPE OF THIS MODULE - read this before looking for the VMs
# -----------------------------------------------------------------------------
# There is no compute tier and no load balancer here. Check sheet features
# 11, 12 and 13 (EC2 fleet, internal ALB, listeners) are N/A under this shape,
# not PARTIAL, because the card-vault binary runs as an OKE workload deployed
# through the same Helm/GitOps flow as every other application - the
# `hyperswitch-card-vault` sub-chart already bundled in `hyperswitch-app`.
#
# This follows the GCP precedent, which is a sequence rather than an opinion:
# GCP BUILT and PROVED a Packer image pipeline + instance template + MIG +
# internal LB for this exact workload (terraform/gcp/packer/locker/,
# packer-manifest.json is the record of a real build), then deliberately tore
# it down and rewrote the module to data-tier + identity + KMS only. That is
# what ships on GCP today. It also sidesteps the OCI custom-image gap
# (oci/vm-tier-and-images.md, P4), which is unresolved and cross-module.
#
# THIS IS AN ORACLE-GATE DECISION AND THE GATE HAS NOT BEEN CONVENED
# (check sheet section 8 decision 1: framework section 4.2, re-architecting a
# module; and section 4.4, the identity mechanism). It is written down here as
# the implemented shape, not as a settled one. If the gate picks the faithful
# VM/ALB port instead, this module gains compute.tf + loadbalancer.tf and its
# stack phase moves from 3 back to 1; nothing in this file changes.
#
# -----------------------------------------------------------------------------
# WHY THIS FILE CREATES oci_psql_db_system DIRECTLY instead of nesting
# composition/database, which is what AWS and GCP both do
# -----------------------------------------------------------------------------
# A real divergence, recorded rather than hidden. Three reasons:
#
#   1. Credential handling. composition/database generates its admin password
#      with random_password and accepts the value landing in Terraform state -
#      documented there, and tolerable for the shared platform database. For
#      the card vault it is not: this module has OCI Vault generate the
#      password server-side so no credential exists as a Terraform value at all
#      (secrets.tf). Nesting would inherit the weaker path.
#   2. Scope containment. The point of the dedicated database is one blast
#      radius. Nesting introduces a cross-module version skew (AWS pins
#      `?ref=database-v0.1.6`; a locker on an older database ref is a silently
#      different security posture) for a resource surface this module needs
#      about a fifth of.
#   3. There is nothing to reuse that is not reproduced here. The sibling
#      module's four hard-won findings - mandatory TLS, no deletion protection,
#      no CMEK, one availability domain - are properties of the OCI service,
#      not of that module, and each is restated at its point of divergence
#      below.
#
# The cost is duplication: a fix to oci_psql_db_system usage in
# composition/database does not reach here. That is the trade, it is real, and
# it is a gate item this module cannot settle on its own.
#
# FOUR THINGS ABOUT OCI DATABASE WITH POSTGRESQL THAT A READER WILL OTHERWISE
# GET WRONG. All four are confirmed against provider 9.0.0's own schema and are
# identical to the findings in composition/database:
#   1. TLS is MANDATORY with no off-switch. The live AWS locker unit sets
#      rds.force_ssl = "0" on its dedicated database; that cannot be
#      reproduced, and the behaviour being blocked is the weaker one
#      (feature 18, NONE - and the one NONE in this port that is an
#      improvement).
#   2. There is NO deletion_protection field. The AWS locker sets it true on
#      both the cluster and the global cluster (feature 19, NONE).
#   3. There is NO customer-managed-key argument. Encryption at rest is
#      Oracle-managed only (feature 17, PARTIAL).
#   4. ap-mumbai-1 has ONE availability domain, so multi-node means fault-domain
#      spread, not AD-level fault tolerance.

resource "oci_psql_db_system" "locker" {
  count = var.create_database ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = local.db_display_name
  description    = "Dedicated PostgreSQL database for the ${var.environment} card vault (PCI-DSS scope). Managed by composition/locker."
  db_version     = var.database_config.db_version

  # Sizing is db-system-level: one shape for every node. AWS's
  # database_config.cluster_instances map has no counterpart - no per-node
  # instance class, no per-node AD pinning, no promotion_tier.
  shape                       = var.database_config.shape
  instance_count              = var.database_config.instance_count
  instance_ocpu_count         = var.database_config.instance_ocpu_count
  instance_memory_size_in_gbs = var.database_config.instance_memory_size_in_gbs

  # Custom engine configuration - the cluster-parameter-group analogue.
  # See the rds.force_ssl note in the header and in configuration.tf.
  config_id    = local.db_configuration_id
  apply_config = local.db_configuration_id != null ? var.database_config.apply_config : null

  # ---------------------------------------------------------------------------
  # Network (check sheet feature 5, FULL)
  # ---------------------------------------------------------------------------
  # subnet_id is singular, private-only and FORCE-NEW. There is no
  # db-subnet-group (AWS's create_db_subnet_group has nothing to map to) and no
  # publicly_accessible toggle, so "private subnet, no public endpoint" is
  # structural rather than configured.
  #
  # The intended subnet is vpc-network's `locker-database` tier, whose route
  # table (`locker-db`) carries NO gateway routes of any kind - not internet,
  # not NAT, not even the service gateway. That is the strongest isolation the
  # VCN offers and it is why the locker's database is not in the shared
  # `database` tier.
  #
  # OCI attaches NSGs inline on the DB resource. AWS needed a paired
  # locker_egress_to_rds / rds_ingress_from_locker rule set on two security
  # groups; here the database is simply a member of the NSG that
  # security-rules writes into. A simplification, not a gap.
  network_details {
    subnet_id                      = var.subnet_id
    nsg_ids                        = local.db_nsg_ids
    is_reader_endpoint_enabled     = var.database_config.is_reader_endpoint_enabled
    primary_db_endpoint_private_ip = var.database_config.primary_db_endpoint_private_ip
  }

  # ---------------------------------------------------------------------------
  # Storage - and the missing customer-managed key (feature 17, PARTIAL)
  # ---------------------------------------------------------------------------
  # THE GAP, STATED WHERE IT BITES: there is no CMEK argument on
  # oci_psql_db_system or oci_psql_configuration in provider 9.0.0 - confirmed
  # against the provider's own JSON schema, and confirmed a second time by
  # oci/modules/database.md section 4.9, which also checked the OCI console's
  # create flow and found no key field there either. The AWS locker sets
  # database_config.storage_encrypted = true with a customer KMS key from its
  # own `module.kms`; the data is still encrypted at rest here, but under an
  # Oracle-managed key that this tenancy cannot rotate, scope or revoke.
  #
  # This module's vault and key (kms.tf) therefore protect the CREDENTIAL and
  # any other Vault secret, and NOT the database's storage. That asymmetry is
  # the single most consequential loss in this port for a PCI-DSS-scoped
  # component and needs an explicit sign-off from whoever owns that scope -
  # check sheet section 4.5, section 10 "Encryption at rest" row (Weaker), and
  # open question 9.4. Do not close it by pointing at kms.tf.
  #
  # PLACEMENT: is_regionally_durable replicates Block Volume across ADs in
  # MULTI-AD regions. ap-mumbai-1 has one AD, so a multi-node system spreads
  # across FAULT DOMAINS inside that one AD. Kept true anyway so the same
  # configuration is correct in any multi-AD region. Both system_type and
  # availability_domain are FORCE-NEW; the provider forbids setting
  # availability_domain alongside is_regionally_durable.
  storage_details {
    system_type           = var.database_config.storage_system_type
    is_regionally_durable = var.database_config.is_regionally_durable
    availability_domain   = var.database_config.is_regionally_durable ? null : var.database_config.availability_domain
    iops                  = var.database_config.storage_iops != null ? tostring(var.database_config.storage_iops) : null
  }

  # ---------------------------------------------------------------------------
  # Credentials - VAULT_SECRET only, by construction
  # ---------------------------------------------------------------------------
  # password_type is hardcoded VAULT_SECRET. The provider also accepts
  # PLAIN_TEXT, and this module deliberately offers no way to reach it: a
  # PLAIN_TEXT password is a Terraform value, and a Terraform value for the
  # card vault's database credential ends up in state. The secret it points at
  # is generated by OCI Vault itself (secrets.tf), so no plaintext exists on
  # this side at any point.
  #
  # Omitted entirely on a warm standby: "Users and roles are replicated from
  # the primary ... The warm standby database can't have dedicated users or
  # roles."
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

  # ---------------------------------------------------------------------------
  # Backup, PITR and maintenance
  # ---------------------------------------------------------------------------
  # TWO POLICIES WHERE AWS HAD ONE NUMBER. On AWS,
  # database_config.backup_retention_period is simultaneously the
  # scheduled-backup retention and the continuous PITR window. On OCI they are
  # independent, and setting backup_policy alone ships the card vault's
  # database with no point-in-time recovery at all. Both are always emitted.
  #
  # C12 - backupStart is a TIME OF DAY, "HH:MM", not an hour, and this file
  # carried the identical bug composition/database did. That is the duplication
  # cost this file's own header warns about, arriving for the first time.
  #
  # A real CreateDbSystem call on 2026-09-04 rejected the bare hour:
  #   400-InvalidParameter, Invalid backupStart 00
  # Oracle ships "02:00" in examples/psql/main.tf and in
  # internal/integrationtest/psql_db_system_test.go at provider v9.0.0, and the
  # provider's own read path does
  #   strings.TrimSuffix(string(*v.BackupStart), " UTC")
  # in all three of BackupPolicyToMap's DAILY/MONTHLY/WEEKLY arms, so the
  # service's wire value is "02:00 UTC". Full citations in the C12 banner in
  # composition/database/main.tf.
  #
  # Hour granularity is kept and the ":00" is appended here, so no caller can
  # construct a malformed backupStart. AWS's "00:51-01:21" therefore becomes
  # 00:00 - 51 to 81 minutes EARLIER than the AWS window, not the "up to 9
  # minutes" this comment claimed before C12.
  #
  # NOT FIXED HERE and still latent in this file: database_config.maintenance_window_start
  # takes "{day-of-week} {time-of-day}" with a THREE-LETTER day ("SUN 12:00"),
  # while backup_days_of_the_week takes the full uppercase enum name ("SUNDAY").
  # Neither is validated on this object-typed variable, and this module also
  # still carries the C9 (configuration shape asymmetry), C10 (override-key
  # allowlist) and C11 (odsp_insight_list mandatory when kind = ENABLED)
  # exposures that composition/database has been fixed for. See the C12 entry in
  # the OCI build log.
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

  # Query Insights - the Performance Insights analogue. Retention is fixed at
  # 7 days server-side, which matches the live AWS
  # performance_insights_retention_period = 7.
  odsp_insight_details {
    kind = var.database_config.query_insights_enabled ? "ENABLED" : "DISABLED"
  }

  # ---------------------------------------------------------------------------
  # Multi-region DR (check sheet feature 16, SUBSTITUTE - section 4.4)
  # ---------------------------------------------------------------------------
  # NOT a rename of Aurora Global Database. There is no global object, no
  # global identifier and no storage-layer replication on OCI; Replication with
  # Warm Standby is a WAL-streaming relationship between two INDEPENDENT db
  # systems, and promotion converts the standby to standalone rather than
  # moving a role inside a shared cluster. The AWS locker's
  # database_config.create_global_cluster / global_cluster_identifier /
  # replication_source_identifier / source_region all collapse into one
  # primary_db_system_id.
  #
  # OFF by default, and the default is a decision. What turning it on costs,
  # for the CARD VAULT specifically:
  #   RPO   300 s floor (default 300, max 10800) against Aurora's 20 s
  #         enforceable floor and sub-second observed lag. On an unplanned
  #         regional failover that is up to five minutes of committed card
  #         data, not one second.
  #   Mode  manual failover only. RTO is however long it takes to page a human.
  #   Bound is_rpo_enforced = true bounds the loss but switches the PRIMARY to
  #         read-only when lag exceeds the threshold - i.e. a DR feature that
  #         can take the card vault offline. false leaves the window unbounded.
  #         There is no third setting.
  #   Cost  a SECOND full db system. Note the locker-specific wrinkle from
  #         check sheet section 4.4: because the vault's database is dedicated,
  #         a passive-region locker needs its own warm-standby pair on top of
  #         the shared database's, doubling the DR footprint - and that
  #         doubling is already committed in production on AWS
  #         (catalog/stacks/passive/terragrunt.stack.hcl).
  #   Loss  restore is forfeited entirely while it is on.
  #
  # A wider RPO on cardholder-data infrastructure is a materially different
  # risk from the same gap on the general transactional database and should be
  # sized and signed off separately - not inherited from the shared database's
  # decision (check sheet section 4.4, section 10 "Multi-region DR" row).
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
    # HARDCODED true, and it has to be: Terraform rejects a variable in a
    # lifecycle block, so this cannot be switched by an input. It is the ONLY
    # Terraform-level guard available, because oci_psql_db_system has no
    # deletion_protection argument of any kind in provider 9.0.0 - the AWS
    # locker's deletion_protection = true and global_deletion_protection = true
    # have no counterpart to port (feature 19, NONE - section 4.7).
    #
    # It protects against accident, not against a determined operator or a
    # corrupted state file, and it is a strictly weaker class of control than
    # AWS's service-enforced flag - which matters more for the card vault's
    # database than for the shared one. Deliberate teardown is a two-step:
    # comment this out on a branch, apply, then destroy. The only control that
    # survives a wrong apply is an IAM policy denying the delete verb on
    # postgres-db-systems outside a break-glass group, and that lives outside
    # this module and is still outstanding.
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

# Endpoints are not attributes of the db system - they come from a separate
# data source. primary_db_endpoint is the stable writer FQDN that a failover
# promotes a replica behind; reader_endpoint is the replica-balanced one.
#
# ca_certificate matters more here than it did on AWS: TLS is mandatory, so the
# card-vault application needs this PEM to connect with sslmode=verify-ca or
# verify-full. Its AWS counterpart connects to a database where the live unit
# has switched TLS enforcement OFF.
data "oci_psql_db_system_connection_detail" "locker" {
  count = var.create_database ? 1 : 0

  db_system_id = oci_psql_db_system.locker[0].id
}
