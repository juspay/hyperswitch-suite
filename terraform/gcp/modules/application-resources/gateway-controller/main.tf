# ============================================================================
# Gateway Controller (GCP equivalent of application-resources/alb-controller)
# ============================================================================
# The AWS Load Balancer Controller is a Helm-installed workload that
# provisions ALBs from Kubernetes Ingress/Gateway resources. GKE has no
# equivalent controller to install: Gateway API and Ingress support are
# built into GKE itself (enabled via `gateway_api_channel` on
# composition/gke), and the Google Cloud Load Balancer controller runs as a
# managed control-plane component, not a workload you deploy.
#
# What this module actually provides, then, is the supporting
# infrastructure a Terraform-managed alb-controller module would otherwise
# own: an SSL policy governing the minimum TLS version/cipher suite for
# GKE-managed load balancers, and (optionally) a Workload Identity binding
# for any BackendConfig/FrontendConfig automation that needs GCP API access.
# The Gateway/HTTPRoute/Ingress *objects themselves* are Kubernetes-native
# resources applied via your GitOps/kubectl flow, not Terraform - the same
# boundary application-resources/istio draws.
#
# Usage:
#   module "gateway_controller" {
#     source = "../../modules/application-resources/gateway-controller"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#   }
# ============================================================================

resource "google_compute_ssl_policy" "gateway" {
  count = var.create_ssl_policy ? 1 : 0

  project         = var.project_id
  name            = "${local.name_prefix}-ssl-policy"
  profile         = var.ssl_policy_profile
  min_tls_version = var.ssl_policy_min_tls_version
}

module "workload_identity" {
  source = "../gke-workload-identity"

  count = var.create_service_account ? 1 : 0

  project_id   = var.project_id
  environment  = var.environment
  project_name = var.project_name
  app_name     = "gateway-controller"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  project_roles = var.additional_project_roles

  labels = local.common_labels
}
