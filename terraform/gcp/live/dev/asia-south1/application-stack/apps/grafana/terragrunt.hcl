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
  source = "../../../../../../modules/application-resources/grafana"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  k8s_namespace            = "monitoring"
  k8s_service_account_name = "grafana"

  use_existing_k8s_sa = false

  additional_project_roles = [
    "roles/monitoring.viewer",
    "roles/logging.viewer",
  ]

  create_database = false
  database_config = {
    network_id = dependency.vpc.outputs.network_id
  }

  host_domains = {
    dev = "grafana.${include.root.locals.domains[0]}"
  }

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "grafana"
    managed_by  = "terraform"
  }
}
