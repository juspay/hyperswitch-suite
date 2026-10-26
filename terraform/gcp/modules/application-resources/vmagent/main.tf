# vmagent: a GSA plus a Workload Identity binding, so the VictoriaMetrics
# agent can use GCE service discovery (roles/compute.viewer). The Kubernetes
# ServiceAccount itself is created by the monitoring Helm release (the
# VictoriaMetrics operator names it vmagent-<fullname>), so this module only
# creates the GCP side and the workloadIdentityUser binding.

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

  roles = var.project_roles
}
