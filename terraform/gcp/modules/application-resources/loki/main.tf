# ============================================================================
# Loki (GCP equivalent of application-resources/loki)
# ============================================================================
# GSA + Workload Identity binding, a GCS bucket for chunk storage, and a
# Pub/Sub topic + notification wired to object-create events on that bucket
# - the GCS+Pub/Sub equivalent of the AWS module's S3 bucket + notification
# + dedicated IAM role/SG.
#
# Usage:
#   module "loki" {
#     source = "../../modules/application-resources/loki"
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
  app_name     = "loki"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  project_roles = var.additional_project_roles

  labels = local.common_labels
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
    member = "serviceAccount:${module.workload_identity.service_account_email}"
  }]

  labels = local.common_labels
}

# ==============================================================================
# Pub/Sub notification on bucket object changes (replaces the AWS module's
# S3 -> aws_s3_bucket_notification wiring)
# ==============================================================================
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
