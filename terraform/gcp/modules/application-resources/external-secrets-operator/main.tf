# ============================================================================
# External Secrets Operator (GCP equivalent of application-resources/external-secrets-operator)
# ============================================================================
# GSA + Workload Identity binding granted read access to Secret Manager,
# scoped either project-wide or to a specific list of secrets - mirroring
# the AWS module's IRSA role + scoped Secrets Manager IAM policy document.
#
# Usage:
#   module "external_secrets_operator" {
#     source = "../../modules/application-resources/external-secrets-operator"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#
#     secret_ids = ["hyperswitch-dev-db-password"]
#   }
# ============================================================================

module "workload_identity" {
  source = "../gke-workload-identity"

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "eso"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.scope_to_project ? concat(["roles/secretmanager.secretAccessor"], var.additional_project_roles) : var.additional_project_roles

  labels = var.labels
}

# ==============================================================================
# Per-secret access (used instead of/alongside the project-wide role above
# when secret_ids is non-empty, for least-privilege scoping)
# ==============================================================================
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = toset(var.secret_ids)

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.service_account_email}"
}
