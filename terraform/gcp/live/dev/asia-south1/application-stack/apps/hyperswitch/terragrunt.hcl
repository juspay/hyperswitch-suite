include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    location       = "asia-south1"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../../modules/application-resources/hyperswitch"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  public_domain = include.root.locals.domains[0]

  cluster_name           = dependency.gke.outputs.cluster_name
  cluster_location       = dependency.gke.outputs.location
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  kms = {
    create = true

    location        = "asia"
    rotation_period = "7776000s"
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

  smtp_secret_id = null

  secret_ids = ["hyperswitch-dev-gcp-kms-secrets"]

  cloud_functions = {
    enabled = false
  }

  cross_project_assume = {
    enabled = false
  }

  additional_custom_role_ids = []

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "hyperswitch"
    managed_by  = "terraform"
  }
}
