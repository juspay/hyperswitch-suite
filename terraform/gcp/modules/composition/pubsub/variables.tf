variable "project_id" {
  description = "GCP project ID where the topic is created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "topic" {
  description = "Logical topic name, auto-prefixed with '<environment>-<project_name>-'"
  type        = string
}

variable "topic_message_retention_duration" {
  description = "How long to retain unacknowledged messages on the topic (e.g. '86400s'). Null uses the service default (7 days)"
  type        = string
  default     = null
}

variable "topic_kms_key_name" {
  description = "Self-link of a KMS CryptoKey used to encrypt messages at rest. Null uses Google-managed encryption"
  type        = string
  default     = null
}

variable "pull_subscriptions" {
  description = "List of pull subscriptions to create, in the shape expected by terraform-google-modules/pubsub"
  type        = any
  default     = []
}

variable "push_subscriptions" {
  description = "List of push subscriptions to create, in the shape expected by terraform-google-modules/pubsub"
  type        = any
  default     = []
}

variable "bigquery_subscriptions" {
  description = "List of BigQuery subscriptions to create, in the shape expected by terraform-google-modules/pubsub"
  type        = any
  default     = []
}

variable "cloud_storage_subscriptions" {
  description = "List of Cloud Storage subscriptions to create, in the shape expected by terraform-google-modules/pubsub"
  type        = any
  default     = []
}

variable "allowed_persistence_regions" {
  description = "List of regions messages may be persisted in. Null leaves the default (global) policy"
  type        = list(string)
  default     = null
}

variable "grant_token_creator" {
  description = <<-EOT
    Whether to grant roles/iam.serviceAccountTokenCreator to the project's
    Pub/Sub service agent. Upstream defaults this to true and creates the
    binding unconditionally, which is a PROJECT-LEVEL IAM grant appearing on
    every topic this module creates.

    It is only actually required for PUSH subscriptions that authenticate to
    their endpoint with an OIDC token - the service agent needs it to mint
    those tokens. A topic with only pull subscriptions does not need it, so
    set false there and keep the grant off the project.
  EOT
  type        = bool
  default     = true
}

variable "labels" {
  description = "Additional labels applied to the topic and subscriptions"
  type        = map(string)
  default     = {}
}
