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

dependency "vpc" {

  config_path = "../../../vpc-network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../../modules/application-resources/superposition"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name           = dependency.gke.outputs.cluster_name
  cluster_location       = dependency.gke.outputs.location
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  k8s_namespace            = "hyperswitch"
  k8s_service_account_name = "superposition"

  create_database = false
  database_config = {

    network_id = dependency.vpc.outputs.network_id
  }

  additional_project_roles = []

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "superposition"
    managed_by  = "terraform"
  }
}
