# ArgoCD: a GSA plus Workload Identity bindings for ArgoCD's controller, server
# and applicationset service accounts, with optional cross-project deployment
# support via cross_project_target_sas.

# The workload_identity module below creates a real kubernetes_service_account_v1;
# without a configured provider it falls back to the zero-config default and
# apply fails with `dial tcp [::1]:80: connect: connection refused`. Declaring
# the provider here rather than in the live layer keeps the live-layer files
# free of embedded Terraform.
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
  namespace    = var.argocd_namespace
  k8s_sa_name  = var.argocd_service_accounts[0]

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  roles = var.additional_project_roles
}

# Cross-project deployment: grant ArgoCD's GSA impersonation rights on target
# service accounts in other projects.
resource "google_service_account_iam_member" "cross_project_impersonation" {
  for_each = toset(var.cross_project_target_service_accounts)

  service_account_id = each.value
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
