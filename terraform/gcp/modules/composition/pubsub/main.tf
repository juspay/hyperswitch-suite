# One Pub/Sub topic plus its subscriptions and IAM. Called once per logical
# topic, by the live layer or by an application-resources module.

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "8.8.0"

  project_id = var.project_id
  topic      = local.topic_name

  topic_labels        = local.common_labels
  subscription_labels = local.common_labels

  topic_message_retention_duration = var.topic_message_retention_duration
  topic_kms_key_name               = var.topic_kms_key_name

  grant_token_creator = var.grant_token_creator

  pull_subscriptions          = var.pull_subscriptions
  push_subscriptions          = var.push_subscriptions
  bigquery_subscriptions      = var.bigquery_subscriptions
  cloud_storage_subscriptions = var.cloud_storage_subscriptions

  message_storage_policy = var.allowed_persistence_regions != null ? {
    allowed_persistence_regions = var.allowed_persistence_regions
  } : {}
}
