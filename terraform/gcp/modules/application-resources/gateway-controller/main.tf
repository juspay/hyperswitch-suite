# Gateway Controller - supporting GCP resources for GKE's load balancing.
#
# There is deliberately no Helm release here: GKE runs both the Ingress (GLBC)
# and Gateway API controllers in Google's managed control plane, so there is no
# chart to install and no IAM role to grant. Gateway API is enabled by a cluster
# field (`gateway_api_channel` on composition/gke), not by this module, and
# Gateway/HTTPRoute/Ingress objects are applied through GitOps rather than
# Terraform.
#
# This module owns:
#   * an SSL policy setting the minimum TLS version and cipher profile for the
#     load balancers GKE creates - attached from a FrontendConfig's
#     `spec.sslPolicy`, using the ssl_policy_name output;
#   * optionally, a Workload Identity-bound service account for your own
#     BackendConfig/FrontendConfig automation that calls GCP APIs.

# Attributes are null unless create_service_account = true, leaving the provider
# unconfigured rather than failing on a base64decode of an absent certificate.
provider "kubernetes" {
  host                   = var.cluster_endpoint != null ? "https://${var.cluster_endpoint}" : null
  cluster_ca_certificate = var.cluster_ca_certificate != null ? base64decode(var.cluster_ca_certificate) : null
  token                  = data.google_client_config.current.access_token
}

resource "google_compute_ssl_policy" "gateway" {
  count = var.create_ssl_policy ? 1 : 0

  project         = var.project_id
  name            = "${local.name_prefix}-ssl-policy"
  profile         = var.ssl_policy_profile
  min_tls_version = var.ssl_policy_min_tls_version

  # Rejected by the API unless profile = CUSTOM.
  custom_features = var.ssl_policy_profile == "CUSTOM" ? var.ssl_policy_custom_features : null
}

module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "44.3.0"

  count = var.create_service_account ? 1 : 0

  project_id = var.project_id
  name       = local.gcp_sa_name

  cluster_name = var.cluster_name
  location     = var.cluster_location
  namespace    = var.k8s_namespace
  k8s_sa_name  = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  roles = var.additional_project_roles
}
