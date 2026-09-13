# Adds a generic OIDC provider to an existing workload identity pool,
# trusting a Kubernetes cluster's own OIDC issuer so a pod can federate to
# GCP using its ServiceAccount token. Attaches to the pool via a data
# source; does not create or modify the pool itself.

data "google_iam_workload_identity_pool" "infraswitch" {
  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
}

resource "google_iam_workload_identity_pool_provider" "infraswitch_k8s" {
  project                            = var.project_id
  workload_identity_pool_id          = data.google_iam_workload_identity_pool.infraswitch.workload_identity_pool_id
  workload_identity_pool_provider_id = "infraswitch-k8s-provider"
  display_name                       = "infra-switch-sa (K8s OIDC)"
  description                        = "EKS cluster ${var.eks_cluster_name}, namespace/SA ${var.k8s_namespace}/${var.k8s_service_account} only"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  # Restricts token exchange to one namespace/ServiceAccount.
  attribute_condition = "assertion.sub == \"system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}\""

  # Unset: defaults to this provider's own canonical resource name. The
  # pod's projected token volume must declare that same value as its
  # audience.
  oidc {
    issuer_uri = var.eks_oidc_issuer_url
  }
}

# Grants project roles directly to the federated identity.
resource "google_project_iam_member" "infraswitch_k8s_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "principal://iam.googleapis.com/${data.google_iam_workload_identity_pool.infraswitch.name}/subject/system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
}
