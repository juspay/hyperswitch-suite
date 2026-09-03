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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/external-secrets-operator?ref=gcp-apps-external-secrets-operator-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  # Project-wide roles/secretmanager.secretAccessor by default; switch to
  # scope_to_project = false + explicit secret_ids for least privilege.
  scope_to_project = true

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
