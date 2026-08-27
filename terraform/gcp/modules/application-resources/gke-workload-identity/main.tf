# ============================================================================
# GKE Workload Identity (GCP equivalent of application-resources/eks-iam)
# ============================================================================
# The generic/legacy variant of the shared IRSA-equivalent contract every
# application-resources module in this tree implements: create a Google
# service account, bind it to a Kubernetes service account via Workload
# Identity, grant it project-level roles and/or a custom role, and
# optionally create a companion GCS bucket + bucket IAM.
#
# Usage:
#   module "app_identity" {
#     source = "../../modules/application-resources/gke-workload-identity"
#
#     project_id   = "hyperswitch-dev"
#     environment  = "dev"
#     project_name = "hyperswitch"
#     app_name     = "my-app"
#
#     cluster_name = module.gke.cluster_name
#     k8s_namespace = "my-app"
#     k8s_service_account_name = "my-app"
#
#     project_roles = ["roles/logging.logWriter"]
#   }
# ============================================================================

module "workload_identity" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version = "44.3.0"

  project_id = var.project_id
  name       = local.gcp_sa_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  k8s_sa_name         = var.k8s_service_account_name
  namespace           = var.k8s_namespace
  cluster_name        = var.cluster_name
  location            = var.cluster_location

  roles = var.project_roles

  annotate_k8s_sa = var.annotate_k8s_sa
}

# ==============================================================================
# Optional companion GCS bucket (mirrors eks-iam's create_s3_bucket)
# ==============================================================================
module "bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = var.create_bucket ? 1 : 0

  project_id    = var.project_id
  name          = local.bucket_name
  location      = var.bucket_location
  force_destroy = var.bucket_force_destroy

  versioning         = var.bucket_enable_versioning
  bucket_policy_only = true

  iam_members = [{
    role   = "roles/storage.objectAdmin"
    member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
  }]

  labels = local.common_labels
}
