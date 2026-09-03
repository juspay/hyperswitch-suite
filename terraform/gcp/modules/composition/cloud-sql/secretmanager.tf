# ============================================================================
# Optional Secret Manager auto-storage for the generated master password
# ============================================================================
# See variable "secret_manager" in variables.tf for the rationale - this
# replicates RDS's `manage_master_user_password` outcome (password never
# leaves Terraform state/provider without also landing in a secret store)
# since Cloud SQL itself has no equivalent native feature.
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
  secret_data = module.cloud_sql.generated_user_password
}
