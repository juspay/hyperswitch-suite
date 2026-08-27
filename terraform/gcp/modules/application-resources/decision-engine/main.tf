# ============================================================================
# Decision Engine (GCP equivalent of application-resources/decision-engine)
# ============================================================================
# GSA + Workload Identity binding, an optional GCS bucket + bucket IAM
# (equivalent of the AWS module's dedicated S3 bucket + policy), and SMTP
# credentials sourced from Secret Manager instead of SES (GCP has no
# first-party transactional email service).
#
# Usage:
#   module "decision_engine" {
#     source = "../../modules/application-resources/decision-engine"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#   }
# ============================================================================

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "decision-engine"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.additional_project_roles

  labels = local.common_labels
}

module "bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = var.create_bucket ? 1 : 0

  project_id    = var.project_id
  name          = local.bucket_name
  location      = var.bucket_location
  force_destroy = var.bucket_force_destroy

  versioning         = true
  bucket_policy_only = true

  iam_members = [{
    role   = "roles/storage.objectAdmin"
    member = "serviceAccount:${module.workload_identity.service_account_email}"
  }]

  labels = local.common_labels
}

# ==============================================================================
# SMTP credentials (replaces SES; sourced from an existing Secret Manager secret)
# ==============================================================================
resource "google_secret_manager_secret_iam_member" "smtp_credentials" {
  count = var.smtp_secret_id != null ? 1 : 0

  project   = var.project_id
  secret_id = var.smtp_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.service_account_email}"
}
