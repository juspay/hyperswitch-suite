output "instance_id" {
  description = "Spanner instance ID"
  value       = google_spanner_instance.this.name

  # Cross-variable checks live here rather than in variable validation blocks,
  # which cannot reference other variables below Terraform 1.9 (this module
  # floors at 1.5). Failing loudly beats a confusing API rejection.

  precondition {
    condition     = length(local.instance_id) >= 6 && length(local.instance_id) <= 30
    error_message = "instance_id must be 6-30 characters; got '${local.instance_id}' (${length(local.instance_id)}). Shorten project_name or set instance_id explicitly."
  }

  precondition {
    condition     = length(local.instance_display_name) >= 4 && length(local.instance_display_name) <= 30
    error_message = "instance_display_name must be 4-30 characters; got '${local.instance_display_name}' (${length(local.instance_display_name)})."
  }

  precondition {
    condition = var.edition != "STANDARD" || length([
      for k, s in local.backup_schedules : k if s.type == "INCREMENTAL"
    ]) == 0
    error_message = "Incremental backup schedules require edition ENTERPRISE or ENTERPRISE_PLUS. Either raise var.edition or set backup_schedule.type = \"FULL\"."
  }

  precondition {
    condition     = !local.any_cmek || startswith(local.instance_config, "regional-")
    error_message = "CMEK here is applied through the API's single-key kms_key_name, which only covers a single-region instance_config. A multi-region config needs one key per region (kms_key_names), which this module does not expose - use Google-managed encryption there."
  }
}

output "instance_name" {
  description = "Fully-qualified instance resource name (projects/<p>/instances/<id>) - the form Spanner client libraries and PGAdapter take"
  value       = "projects/${var.project_id}/instances/${google_spanner_instance.this.name}"
}

output "instance_config" {
  description = "Instance configuration (topology) actually in effect"
  value       = google_spanner_instance.this.config
}

output "instance_state" {
  description = "Instance status - CREATING or READY"
  value       = google_spanner_instance.this.state
}

output "edition" {
  description = "Edition the instance runs at"
  value       = google_spanner_instance.this.edition
}

output "capacity" {
  description = "Compute capacity in effect. With autoscaling enabled num_nodes/processing_units are reported by the API rather than set by config"
  value = {
    num_nodes        = google_spanner_instance.this.num_nodes
    processing_units = google_spanner_instance.this.processing_units
    autoscaling      = local.autoscaling != null
  }
}

output "database_ids" {
  description = "Database IDs keyed by database name"
  value       = { for k, db in google_spanner_database.this : k => db.id }
}

output "database_names" {
  description = "Fully-qualified database resource names keyed by database name - the projects/<p>/instances/<i>/databases/<d> form clients connect with"
  value = {
    for k, db in google_spanner_database.this :
    k => "projects/${var.project_id}/instances/${google_spanner_instance.this.name}/databases/${db.name}"
  }
}

output "database_dialects" {
  description = "Dialect each database was created with, keyed by database name"
  value       = { for k, db in google_spanner_database.this : k => db.database_dialect }
}

output "postgres_database_names" {
  description = "Names of the POSTGRESQL-dialect databases only - the ones PGAdapter can front"
  value       = [for k, d in local.databases : k if d.database_dialect == "POSTGRESQL"]
}

output "pgadapter_connection" {
  description = <<-EOT
    Everything PGAdapter needs to be pointed at this instance, as
    { project, instance, databases }. PGAdapter is NOT deployed by this module;
    a libpq client cannot reach these databases until something runs it.
  EOT
  value = {
    project   = var.project_id
    instance  = google_spanner_instance.this.name
    databases = [for k, d in local.databases : k if d.database_dialect == "POSTGRESQL"]
  }
}

output "backup_schedule_ids" {
  description = "Backup schedule IDs keyed by database name, for the databases that configured one"
  value       = { for k, s in google_spanner_backup_schedule.this : k => s.id }
}

output "kms_key_name" {
  description = "Self-link of the KMS key used for database encryption, if any"
  value       = local.kms_key_name
}

output "service_agent_email" {
  description = "Spanner service agent granted encrypt/decrypt on the CMEK key, if CMEK is in use"
  value       = local.any_cmek ? google_project_service_identity.spanner[0].email : null
}
