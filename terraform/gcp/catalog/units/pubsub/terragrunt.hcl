# General-purpose shared topic for cross-service eventing (the loki/vector
# apps units create their own dedicated topics internally for log-bucket
# notifications - this one is for application-level events).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/pubsub?ref=gcp-pubsub-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  topic = "events"

  topic_message_retention_duration = "604800s" # 7 days

  pull_subscriptions = [
    {
      name                 = "events-consumer"
      ack_deadline_seconds = 60
    },
  ]

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
