# Hyperswitch application resources: a GSA plus a Workload Identity binding,
# and a set of optional feature toggles.
#
#   kms                  -> kms.tf (Cloud KMS keyring/key)
#   gcs_dashboard_themes -> gcs.tf (GCS bucket)
#   gcs_file_uploads     -> gcs.tf (GCS bucket)
#   smtp_secret_id       -> Secret Manager access for SMTP credentials
#   secret_ids           -> Secret Manager secret access
#   cloud_functions      -> Cloud Functions invoker access
#   cross_project_assume -> service account impersonation

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "44.3.0"

  project_id = var.project_id
  name       = local.gcp_sa_name

  cluster_name = var.cluster_name
  location     = var.cluster_location
  namespace    = var.k8s_namespace
  k8s_sa_name  = var.k8s_service_account_name

  roles = var.additional_project_roles
}

# Secret Manager access
resource "google_secret_manager_secret_iam_member" "secrets" {
  for_each = local.secrets_manager_enabled ? toset(var.secret_ids) : []

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "smtp" {
  count = local.smtp_enabled ? 1 : 0

  project   = var.project_id
  secret_id = var.smtp_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

# Cloud Functions invoker access
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  for_each = local.lambda_enabled ? toset(var.cloud_functions.function_names) : []

  project        = var.project_id
  location       = var.cloud_functions.location
  cloud_function = each.value
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

# Cross-project service account impersonation
resource "google_service_account_iam_member" "cross_project_impersonation" {
  for_each = local.cross_project_enabled ? toset(var.cross_project_assume.target_service_accounts) : []

  service_account_id = each.value
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

# Additional custom IAM roles
resource "google_project_iam_member" "additional_custom_roles" {
  for_each = toset(var.additional_custom_role_ids)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
