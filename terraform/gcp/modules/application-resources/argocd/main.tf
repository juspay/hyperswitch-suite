# ============================================================================
# ArgoCD (GCP equivalent of application-resources/argocd)
# ============================================================================
# GSA + Workload Identity binding for ArgoCD's controller/server/
# applicationset service accounts, plus optional cross-project deployment
# support. AWS's cross-account `sts:AssumeRole` has no single GCP
# equivalent; the nearest is granting ArgoCD's service account
# `roles/iam.serviceAccountTokenCreator` on target service accounts in
# other projects, which it then impersonates - so `cross_project_target_sas`
# plays the role of the AWS module's `cross_account_roles`.
#
# Usage:
#   module "argocd" {
#     source = "../../modules/application-resources/argocd"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#
#     cluster_name     = module.gke.cluster_name
#     cluster_location = module.gke.location
#   }
# ============================================================================

# ==============================================================================
# This module's own kubernetes provider.
#
# `../gke-workload-identity` (below) wraps terraform-google-modules/
# kubernetes-engine//modules/workload-identity, which creates a real
# `kubernetes_service_account_v1`. With no configured kubernetes provider
# that resource falls back to the provider's zero-config default and apply
# fails with `dial tcp [::1]:80: connect: connection refused`. Declaring the
# provider here (rather than in the live layer via a Terragrunt `generate`
# block) keeps the live-layer files free of embedded Terraform - default-
# provider inheritance makes this config available to the child module.
# Same pattern as ../hyperswitch, ../superposition and ../istio.
# ==============================================================================
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
  app_name     = "argocd"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.argocd_namespace
  k8s_service_account_name = var.argocd_service_accounts[0]

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  project_roles = var.additional_project_roles

  labels = var.labels
}

# ==============================================================================
# Cross-project deployment: grant ArgoCD's GSA impersonation rights on
# target service accounts in other projects
# ==============================================================================
resource "google_service_account_iam_member" "cross_project_impersonation" {
  for_each = toset(var.cross_project_target_service_accounts)

  service_account_id = each.value
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.workload_identity.service_account_email}"
}
