# Scheduled backups, one optional schedule per database.
#
# A backup schedule is OWNED by its database and is deleted along with it. The
# backups it has already taken are not deleted - those are governed by
# retention_duration, and are what var.force_destroy on the instance exists to
# clean up.
#
# This is separate from, and complementary to, the database's
# version_retention_period: that gives point-in-time recovery within a 1h-7d
# window on the live database, while these are independent copies that survive
# the database itself.
resource "google_spanner_backup_schedule" "this" {
  for_each = local.backup_schedules

  project  = var.project_id
  instance = google_spanner_instance.this.name
  database = google_spanner_database.this[each.key].name

  name = each.value.name

  retention_duration = each.value.retention_duration

  spec {
    cron_spec {
      # Allowed frequencies are 12 hour, 1 day, 1 week and 1 month; the version
      # time is always UTC.
      text = each.value.cron
    }
  }

  # Exactly one of these two blocks must be present. INCREMENTAL requires
  # edition ENTERPRISE or above - on STANDARD the API rejects it.
  dynamic "full_backup_spec" {
    for_each = each.value.type == "FULL" ? [1] : []
    content {}
  }

  dynamic "incremental_backup_spec" {
    for_each = each.value.type == "INCREMENTAL" ? [1] : []
    content {}
  }

  encryption_config {
    encryption_type = each.value.encryption_type
  }
}
