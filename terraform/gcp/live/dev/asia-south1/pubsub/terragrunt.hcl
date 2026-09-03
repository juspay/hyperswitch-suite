include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/pubsub"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  topic = "events"

  topic_message_retention_duration = "604800s"

  pull_subscriptions = [
    {
      name                 = "events-consumer"
      ack_deadline_seconds = 60
    },
  ]

  grant_token_creator = false

  allowed_persistence_regions = [include.root.locals.region]

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "pubsub"
    managed_by  = "terraform"
  }
}
