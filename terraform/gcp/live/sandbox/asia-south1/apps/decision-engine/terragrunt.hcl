# smtp_secret_id defaults to null - no Secret Manager secret with SMTP
# credentials exists until values.smtp_secret_id is set (see the module's
# own header comment: GCP has no SES equivalent).

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    cluster_name = "mock-cluster"
    location     = "asia-south1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/decision-engine?ref=gcp-apps-decision-engine-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  create_bucket   = true
  bucket_location = include.root.locals.region

  smtp_secret_id = try(values.smtp_secret_id, null)

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
