# ============================================================================
# Vector (GCP equivalent of application-resources/vector)
# ============================================================================
# GSA + Workload Identity binding, a GCS log bucket, and a Pub/Sub
# topic + pull subscription wired to object-create events on that bucket -
# the GCS+Pub/Sub equivalent of the AWS module's S3 + SQS + cross-region SQS
# read shape. A Pub/Sub subscription can itself be read from another region
# without any special "cross-region" resource (Pub/Sub is a global service),
# so cross-region reads are just IAM grants to a remote reader identity
# rather than a second queue.
#
# Usage:
#   module "vector" {
#     source = "../../modules/application-resources/vector"
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
  app_name     = "vector"

  cluster_name             = var.cluster_name
  cluster_location         = var.cluster_location
  k8s_namespace            = var.k8s_namespace
  k8s_service_account_name = var.k8s_service_account_name

  use_existing_k8s_sa = var.use_existing_k8s_sa
  annotate_k8s_sa     = var.annotate_k8s_sa

  project_roles = var.additional_project_roles

  labels = local.common_labels
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
    member = "serviceAccount:${module.workload_identity.service_account_email}"
  }]

  labels = local.common_labels
}

# ==============================================================================
# Pub/Sub (replaces the AWS module's SQS queue + policy + S3 notification)
# ==============================================================================
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
  member       = "serviceAccount:${module.workload_identity.service_account_email}"
}

# ==============================================================================
# Cross-region read: grant a remote reader identity subscriber access, the
# GCP equivalent of the AWS module's cross-region SQS read policy
# ==============================================================================
resource "google_pubsub_subscription_iam_member" "cross_region_reader" {
  for_each = var.create_queue ? toset(var.cross_region_reader_members) : []

  project      = var.project_id
  subscription = google_pubsub_subscription.log_events[0].name
  role         = "roles/pubsub.subscriber"
  member       = each.value
}
