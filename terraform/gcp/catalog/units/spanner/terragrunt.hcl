# Cloud Spanner with the PostgreSQL interface — an additional database
# alongside `alloydb`, not a replacement for it.
#
# Shipped MINIMAL: 100 processing units (the API floor, 1/10 of a node) on a
# single-region topology, one POSTGRESQL-dialect database. Every knob is
# settable from the stack, so scaling to production capacity is a values edit,
# not a module change.
#
# NO `dependency` BLOCK, AND THAT IS CORRECT. Spanner is a global,
# IAM-authenticated API endpoint — no VPC attachment, no Private Service
# Access range, no private IP. It is one of the few units here that needs
# nothing from `vpc-network` (artifact-registry and gateway-controller are the
# others). Do not add one to "match" the alloydb unit.
#
# KNOWN GAP — the databases this unit creates are NOT reachable by a libpq
# client. `database_dialect = "POSTGRESQL"` gives PostgreSQL syntax and
# semantics, not the PostgreSQL wire protocol; psql/diesel/tokio-postgres need
# PGAdapter proxying in front of it. PGAdapter is deliberately not part of this
# unit — it is a GKE workload, so it belongs in application-stack/apps once a
# module for it lands. Until then only Spanner client libraries can reach these
# databases.
#
# There is also no username/password anywhere in this unit, and that is not an
# omission: Spanner has no bootstrap user. Access is roles/spanner.databaseUser
# granted through `values.spanner.database_iam_members`.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  # ?ref=feat/gcp-iam-infraswitch-federation-unit, not the gcp-spanner-v0.1.0
  # tag: that tag was never pushed (git ls-remote --tags confirms it doesn't
  # exist), so it 404s on fetch. Repoint to a real tag once one is cut for
  # this module.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/spanner?ref=feat/gcp-iam-infraswitch-federation-unit"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  # Topology, not a region. Defaults inside the module to
  # "regional-<region>"; set values.spanner.instance_config to go
  # multi-region. Note there is no India multi-region config — "asia1" is
  # Tokyo/Osaka/Seoul.
  instance_config = try(values.spanner.instance_config, null)

  # STANDARD unless raised. INCREMENTAL backup schedules need ENTERPRISE or
  # above, and the module fails a precondition rather than letting the API
  # reject the apply.
  edition = try(values.spanner.edition, "STANDARD")

  # Exactly one of processing_units / num_nodes / autoscaling. 100 PU is the
  # floor and the cheapest way to stand a dev instance up; 1000 PU = 1 node.
  instance_size = try(values.spanner.instance_size, { processing_units = 100 })

  # Keyed by database name. Defaults to a single POSTGRESQL-dialect
  # "hyperswitch" database with a 3-day point-in-time-recovery window.
  #
  # `ddl` is bootstrap schema only — Terraform does not drift-detect it, and
  # editing an existing statement plans a REPLACEMENT of the database, which
  # destroys its data. Real migrations belong in a migration tool.
  databases = try(values.spanner.databases, {
    hyperswitch = {
      database_dialect         = "POSTGRESQL"
      version_retention_period = "3d"
    }
  })

  # Spanner's entire authentication story. roles/spanner.databaseUser is what
  # an application — or PGAdapter acting on its behalf — needs to read and
  # write.
  instance_iam_members = try(values.spanner.instance_iam_members, [])
  database_iam_members = try(values.spanner.database_iam_members, [])

  # Terraform-side guard on each database. Must be flipped and applied BEFORE
  # a destroy is attempted, not alongside it — the same constraint gke and
  # alloydb have. For an API-side guard that also protects the parent
  # instance, set enable_drop_protection on the database instead.
  deletion_protection = try(values.spanner.deletion_protection, true)

  # Only bites on a destroy, and only for backups taken outside Terraform.
  force_destroy = try(values.spanner.force_destroy, false)

  # AUTOMATIC would give a default backup schedule to databases created
  # outside Terraform too. Left NONE so backups are declared per database.
  default_backup_schedule_type = try(values.spanner.default_backup_schedule_type, "NONE")

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "database"
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
