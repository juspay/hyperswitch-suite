# ============================================================================
# Optional Secret Manager auto-storage for the generated master password
# ============================================================================
# Same pattern as composition/cloud-sql's secret_manager toggle - see that
# module's secretmanager.tf for the rationale (no native AlloyDB/Cloud SQL
# equivalent of RDS's manage_master_user_password).
resource "google_secret_manager_secret" "master_password" {
  count = local.secret_manager_create ? 1 : 0

  project   = var.project_id
  secret_id = local.secret_manager_secret_id

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "master_password" {
  count = local.secret_manager_create ? 1 : 0

  secret      = google_secret_manager_secret.master_password[0].id
  secret_data = local.master_password
}
