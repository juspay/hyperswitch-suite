# GCS Buckets (dashboard themes, file uploads)
module "dashboard_themes_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = local.gcs_dashboard_themes_enabled && var.gcs_dashboard_themes.create ? 1 : 0

  project_id    = var.project_id
  name          = local.dashboard_themes_bucket_name
  location      = var.gcs_dashboard_themes.location
  force_destroy = coalesce(var.gcs_dashboard_themes.force_destroy, false)
  versioning    = coalesce(var.gcs_dashboard_themes.versioning_enabled, true)

  bucket_policy_only = true

  iam_members = [{
    role   = "roles/storage.objectViewer"
    member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
  }]

  labels = local.common_labels
}

module "file_uploads_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = local.gcs_file_uploads_enabled && var.gcs_file_uploads.create ? 1 : 0

  project_id    = var.project_id
  name          = local.file_uploads_bucket_name
  location      = var.gcs_file_uploads.location
  force_destroy = coalesce(var.gcs_file_uploads.force_destroy, false)
  versioning    = coalesce(var.gcs_file_uploads.versioning_enabled, true)

  bucket_policy_only = true

  iam_members = [{
    role   = "roles/storage.objectAdmin"
    member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
  }]

  labels = local.common_labels
}

# Grant access to an existing bucket when create = false
resource "google_storage_bucket_iam_member" "existing_dashboard_themes" {
  count = local.gcs_dashboard_themes_enabled && !var.gcs_dashboard_themes.create ? 1 : 0

  bucket = var.gcs_dashboard_themes.bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

resource "google_storage_bucket_iam_member" "existing_file_uploads" {
  count = local.gcs_file_uploads_enabled && !var.gcs_file_uploads.create ? 1 : 0

  bucket = var.gcs_file_uploads.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
