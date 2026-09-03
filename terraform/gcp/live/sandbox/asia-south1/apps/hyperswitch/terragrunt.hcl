# The core application. KMS + GCS buckets created internally; SMTP left
# unwired by default (see decision-engine's unit for the same
# GCP-has-no-SES note).

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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/hyperswitch?ref=gcp-apps-hyperswitch-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  public_domain = values.domains.api

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  kms = {
    create          = true
    location        = include.root.locals.region
    rotation_period = "7776000s" # 90 days
  }

  gcs_dashboard_themes = {
    create             = true
    location           = include.root.locals.region
    versioning_enabled = true
  }

  gcs_file_uploads = {
    create             = true
    location           = include.root.locals.region
    versioning_enabled = true
  }

  smtp_secret_id = try(values.smtp_secret_id, null)

  secret_ids = []

  cloud_functions = {
    enabled = false
  }

  cross_project_assume = {
    enabled = false
  }

  additional_custom_role_ids = []

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
    component   = "hyperswitch"
  }
}
