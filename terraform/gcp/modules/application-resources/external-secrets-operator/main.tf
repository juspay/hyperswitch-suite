# External Secrets Operator: a GSA plus a Workload Identity binding, granted
# read access to Secret Manager.
#
# Workload Identity binds a GSA to exactly one namespace/KSA pair in one
# cluster's identity pool, so there is no multi-cluster map here - a second
# cluster means a second instantiation of this module.

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
  namespace    = var.k8s_namespace
  k8s_sa_name  = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  roles = local.project_roles
}

# Per-secret access, for least-privilege scoping instead of (or alongside) the
# project-wide grant above. Note that an empty secret_ids with
# scope_to_project = false grants the operator nothing at all, and every
# ExternalSecret it reconciles then fails with a permission error.
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = toset(var.secret_ids)

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}
