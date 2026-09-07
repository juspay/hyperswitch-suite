# Loki: a GSA plus a Workload Identity binding, a GCS bucket for chunk storage,
# and a Pub/Sub topic + notification wired to object-create events on it.

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

  roles = var.additional_project_roles
}

module "chunks_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  project_id    = var.project_id
  name          = local.bucket_name
  location      = var.bucket_location
  force_destroy = var.bucket_force_destroy

  versioning         = false
  bucket_policy_only = true

  lifecycle_rules = var.bucket_lifecycle_rules

  iam_members = [{
    role   = "roles/storage.objectAdmin"
    member = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
  }]

  labels = local.common_labels
}

# Pub/Sub notification on bucket object changes
resource "google_pubsub_topic" "bucket_notifications" {
  count = var.enable_bucket_notifications ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-bucket-events"
  labels  = local.common_labels
}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  count = var.enable_bucket_notifications ? 1 : 0

  project = var.project_id
  topic   = google_pubsub_topic.bucket_notifications[0].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.this[0].email_address}"
}

data "google_storage_project_service_account" "this" {
  count = var.enable_bucket_notifications ? 1 : 0

  project = var.project_id
}

resource "google_storage_notification" "chunks" {
  count = var.enable_bucket_notifications ? 1 : 0

  bucket         = module.chunks_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.bucket_notifications[0].id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publisher]
}
