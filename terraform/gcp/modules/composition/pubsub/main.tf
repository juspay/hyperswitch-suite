# ============================================================================
# Pub/Sub (GCP equivalent of composition/sns)
# ============================================================================
# One topic plus its subscriptions/IAM, matching the AWS module's
# topic+subscription+policy shape. Called once per logical topic; the live
# layer (or an application-resources module like vector/loki) instantiates
# it per notification channel.
#
# Usage:
#   module "pubsub" {
#     source = "../../modules/composition/pubsub"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#     topic       = "vector-log-events"
#
#     pull_subscriptions = [{ name = "vector-consumer" }]
#   }
# ============================================================================

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "8.8.0"

  project_id = var.project_id
  topic      = local.topic_name

  topic_labels        = local.common_labels
  subscription_labels = local.common_labels

  topic_message_retention_duration = var.topic_message_retention_duration
  topic_kms_key_name               = var.topic_kms_key_name

  pull_subscriptions          = var.pull_subscriptions
  push_subscriptions          = var.push_subscriptions
  bigquery_subscriptions      = var.bigquery_subscriptions
  cloud_storage_subscriptions = var.cloud_storage_subscriptions

  message_storage_policy = var.allowed_persistence_regions != null ? {
    allowed_persistence_regions = var.allowed_persistence_regions
  } : {}
}
