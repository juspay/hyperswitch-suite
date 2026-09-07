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
  source = "../../../../../..//modules/application-resources/vector"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  k8s_namespace            = "vector"
  k8s_service_account_name = "vector-logging"

  use_existing_k8s_sa = false

  additional_project_roles = []

  create_bucket          = true
  bucket_name            = null
  bucket_location        = include.root.locals.region
  bucket_force_destroy   = false
  bucket_lifecycle_rules = []

  create_queue                            = true
  subscription_ack_deadline_seconds       = 60
  subscription_message_retention_duration = "604800s"

  cross_region_reader_members = []

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "vector"
    managed_by  = "terraform"
  }
}
