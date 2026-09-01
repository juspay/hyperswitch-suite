# ============================================================================
# Hyperswitch (GCP equivalent of application-resources/hyperswitch)
# ============================================================================
# The largest application-resources module: GSA + Workload Identity binding,
# plus a set of optional feature toggles mirroring the AWS module's object-
# shaped inputs and matching <feature>_enabled/<feature>_*_arn output pairs.
#
# Feature mapping vs. the AWS module:
#   kms                 -> kms.tf (Cloud KMS keyring/key)
#   s3_dashboard_themes -> gcs.tf (GCS bucket)
#   s3_file_uploads     -> gcs.tf (GCS bucket)
#   ses                 -> smtp_secret_id (Secret Manager; GCP has no SES analog)
#   secrets_manager     -> secret_ids (Secret Manager secret access)
#   lambda              -> cloud_functions (Cloud Functions invoker access)
#   assume_role         -> cross_project_assume (service account impersonation)
#   additional_iam_policies -> additional_project_roles / additional_custom_roles
#
# Usage:
#   module "hyperswitch" {
#     source = "../../modules/application-resources/hyperswitch"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#
#     kms                  = { create = true }
#     gcs_dashboard_themes = { create = true }
#     gcs_file_uploads     = { create = true }
#   }
# ============================================================================

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${var.cluster_endpoint}"
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "hyperswitch"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.additional_project_roles

  labels = local.common_labels
}

# ==============================================================================
# Secrets Manager access (replaces AWS module's secrets_manager feature)
# ==============================================================================
resource "google_secret_manager_secret_iam_member" "secrets" {
  for_each = local.secrets_manager_enabled ? toset(var.secret_ids) : []

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.service_account_email}"
}

resource "google_secret_manager_secret_iam_member" "smtp" {
  count = local.smtp_enabled ? 1 : 0

  project   = var.project_id
  secret_id = var.smtp_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.service_account_email}"
}

# ==============================================================================
# Cloud Functions invoker access (replaces AWS module's lambda feature)
# ==============================================================================
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  for_each = local.lambda_enabled ? toset(var.cloud_functions.function_names) : []

  project        = var.project_id
  location       = var.cloud_functions.location
  cloud_function = each.value
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${module.workload_identity.service_account_email}"
}

# ==============================================================================
# Cross-project impersonation (replaces AWS module's assume_role feature)
# ==============================================================================
resource "google_service_account_iam_member" "cross_project_impersonation" {
  for_each = local.cross_project_enabled ? toset(var.cross_project_assume.target_service_accounts) : []

  service_account_id = each.value
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.workload_identity.service_account_email}"
}

# ==============================================================================
# Additional custom IAM roles (replaces AWS module's additional_iam_policies)
# ==============================================================================
resource "google_project_iam_member" "additional_custom_roles" {
  for_each = toset(var.additional_custom_role_ids)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${module.workload_identity.service_account_email}"
}
