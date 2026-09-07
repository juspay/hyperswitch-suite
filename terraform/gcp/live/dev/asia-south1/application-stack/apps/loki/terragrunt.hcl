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
  source = "../../../../../..//modules/application-resources/loki"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  k8s_namespace            = "loki"
  k8s_service_account_name = "loki"

  use_existing_k8s_sa = false

  additional_project_roles = []

  bucket_name          = null
  bucket_location      = include.root.locals.region
  bucket_force_destroy = false

  bucket_lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    },
  ]

  enable_bucket_notifications = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "loki"
    managed_by  = "terraform"
  }
}
