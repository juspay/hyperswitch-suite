# Cloud Spanner with the PostgreSQL interface.
#
# Written against the native google_spanner_* resources rather than the
# registry module, unlike composition/alloydb which wraps
# GoogleCloudPlatform/alloy-db to dodge a provider bug. The reason is specific
# and worth stating so nobody "simplifies" this back later:
# GoogleCloudPlatform/cloud-spanner (v1.2.1) exposes databases through a
# `database_config` object with no `database_dialect` key, so it can only ever
# create GOOGLE_STANDARD_SQL databases. A PostgreSQL-dialect database is not
# expressible through it.
#
# HOW THIS DIFFERS FROM EVERY OTHER DATA UNIT IN THIS CATALOG
#
#   - No network. Spanner is a global, IAM-authenticated API endpoint. There is
#     no network_id, no Private Service Access range, no private IP, and
#     therefore no dependency on composition/vpc-network.
#   - No bootstrap user. There is no username, no password, no Secret Manager
#     entry. Access is roles/spanner.databaseUser on a principal - see iam.tf.
#   - No replicas. Read scaling and replication are properties of
#     instance_config (regional vs multi-region), not separate resources the
#     way AlloyDB read pools are.
#
# WIRE PROTOCOL CAVEAT: database_dialect = "POSTGRESQL" gives PostgreSQL syntax
# and semantics, NOT the PostgreSQL wire protocol. A libpq/diesel/tokio-postgres
# client cannot dial this database directly; it needs PGAdapter in front. This
# module deliberately stops at the data tier - see README.

resource "google_spanner_instance" "this" {
  project = var.project_id

  name         = local.instance_id
  config       = local.instance_config
  display_name = local.instance_display_name
  edition      = var.edition

  # Exactly one of these three carries a value; variables.tf enforces it. When
  # autoscaling_config is set the API treats the other two as OUTPUT_ONLY and
  # reports current capacity through them.
  num_nodes        = var.instance_size.num_nodes
  processing_units = var.instance_size.processing_units

  dynamic "autoscaling_config" {
    for_each = local.autoscaling != null ? [local.autoscaling] : []

    content {
      autoscaling_limits {
        min_processing_units = autoscaling_config.value.min_processing_units
        max_processing_units = autoscaling_config.value.max_processing_units
        min_nodes            = autoscaling_config.value.min_nodes
        max_nodes            = autoscaling_config.value.max_nodes
      }

      autoscaling_targets {
        high_priority_cpu_utilization_percent = autoscaling_config.value.high_priority_cpu_utilization_percent
        storage_utilization_percent           = autoscaling_config.value.storage_utilization_percent
      }
    }
  }

  default_backup_schedule_type = var.default_backup_schedule_type
  force_destroy                = var.force_destroy

  labels = local.common_labels
}

resource "google_spanner_database" "this" {
  for_each = local.databases

  # The CMEK grant must land BEFORE the database is created; nothing in the
  # arguments below references it, so the ordering has to be stated explicitly
  # or Terraform is free to create the database first. Same failure mode
  # composition/alloydb documents for its instance.
  depends_on = [google_kms_crypto_key_iam_member.spanner_service_agent]

  project  = var.project_id
  instance = google_spanner_instance.this.name
  name     = each.key

  database_dialect = each.value.database_dialect

  # Appending to this list is an in-place update. Editing or removing an
  # existing statement plans a REPLACEMENT of the database - which destroys its
  # data. Schema migrations belong in a migration tool, not here; this is for
  # the bootstrap schema only.
  ddl = each.value.ddl

  version_retention_period = each.value.version_retention_period

  deletion_protection    = each.value.deletion_protection
  enable_drop_protection = each.value.enable_drop_protection

  dynamic "encryption_config" {
    for_each = each.value.kms_key_name != null ? [each.value.kms_key_name] : []

    content {
      kms_key_name = encryption_config.value
    }
  }
}
