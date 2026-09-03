# AlloyDB — the primary Postgres for the application stack.
#
# GCP's Aurora-equivalent: disaggregated storage, sub-second-ish failover on
# REGIONAL primaries, read pools sharing the primary's storage layer. This
# unit replaces an earlier `cloud-sql` unit — composition/cloud-sql is not on
# main, and AlloyDB is what the live GCP environment actually runs.
#
# Shipped MINIMAL: one ZONAL primary, no read pools. Every knob is settable
# from the stack, so scaling to production HA (REGIONAL primary + read pools)
# is a values edit, not a module change.
#
# KNOWN GAP: AlloyDB has no Terraform resource for creating an
# application-level database inside the cluster (no `google_alloydb_database`
# exists) — only cluster / instance / user. Creating the per-service databases
# needs a separate psql step once the instance is up; this unit does not do it.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_id                        = "projects/mock/global/networks/mock-vpc"
    private_service_access_range_name = "mock-psa-range"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/alloydb?ref=gcp-alloydb-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network_id = dependency.vpc.outputs.network_id

  # AlloyDB's network_config.allocated_ip_range wants the reserved PSA range's
  # NAME, not a CIDR. Read from the vpc-network unit rather than hardcoded —
  # the module exposes this output, so the live layer's earlier
  # hardcoded-name workaround is no longer needed here.
  allocated_ip_range = dependency.vpc.outputs.private_service_access_range_name

  database_version = try(values.alloydb.database_version, "POSTGRES_15")
  master_username  = try(values.alloydb.master_username, "hyperswitch_admin")

  # master_password left unset — the module generates one and writes it to
  # Secret Manager (AlloyDB has no built-in generation the way Cloud SQL's
  # registry module does).
  secret_manager = {
    create = true
  }

  # A cluster has exactly ONE primary instance; read scaling is read pools,
  # each fronting node_count identical nodes over the primary's storage.
  primary_instance = {
    availability_type = try(values.alloydb.availability_type, "ZONAL")
    cpu_count         = try(values.alloydb.cpu_count, 2)
  }

  # Keyed by pool name. A production HA layout sets availability_type to
  # REGIONAL above and adds e.g. { read-1 = { node_count = 2, cpu_count = 4 } }.
  read_pool_instances = try(values.alloydb.read_pool_instances, {})

  continuous_backup_enabled              = true
  continuous_backup_recovery_window_days = 14
  automated_backup_enabled               = true
  automated_backup_retention_count       = 14

  # Must be flipped and applied BEFORE a destroy is attempted, not alongside
  # it — the same constraint gke's deletion_protection has.
  deletion_protection = try(values.alloydb.deletion_protection, true)

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "database"
    managed_by  = "terraform"
  }
}
