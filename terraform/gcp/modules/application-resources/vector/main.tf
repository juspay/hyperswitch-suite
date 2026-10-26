# Vector: a GSA plus a Workload Identity binding, a GCS log bucket, and a
# Pub/Sub topic + pull subscription wired to object-create events on it.
#
# Pub/Sub is a global service, so a subscription can be read from another region
# with no second queue - a cross-region read is just an IAM grant to the remote
# reader identity.

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

module "logs_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "12.3.0"

  count = var.create_bucket ? 1 : 0

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

# Pub/Sub topic and subscription for bucket object-create events
resource "google_pubsub_topic" "log_events" {
  count = var.create_queue ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-log-events"
  labels  = local.common_labels
}

data "google_storage_project_service_account" "this" {
  count = var.create_bucket && var.create_queue ? 1 : 0

  project = var.project_id
}

resource "google_pubsub_topic_iam_member" "gcs_publisher" {
  count = var.create_bucket && var.create_queue ? 1 : 0

  project = var.project_id
  topic   = google_pubsub_topic.log_events[0].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.this[0].email_address}"
}

resource "google_storage_notification" "logs" {
  count = var.create_bucket && var.create_queue ? 1 : 0

  bucket         = module.logs_bucket[0].name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.log_events[0].id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_pubsub_topic_iam_member.gcs_publisher]
}

resource "google_pubsub_subscription" "log_events" {
  count = var.create_queue ? 1 : 0

  project = var.project_id
  name    = "${local.name_prefix}-log-events-sub"
  topic   = google_pubsub_topic.log_events[0].id

  ack_deadline_seconds       = var.subscription_ack_deadline_seconds
  message_retention_duration = var.subscription_message_retention_duration
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  count = var.create_queue ? 1 : 0

  project      = var.project_id
  subscription = google_pubsub_subscription.log_events[0].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${module.workload_identity.gcp_service_account_email}"
}

# Cross-region read: grant a remote reader identity subscriber access
resource "google_pubsub_subscription_iam_member" "cross_region_reader" {
  for_each = var.create_queue ? toset(var.cross_region_reader_members) : []

  project      = var.project_id
  subscription = google_pubsub_subscription.log_events[0].name
  role         = "roles/pubsub.subscriber"
  member       = each.value
}
