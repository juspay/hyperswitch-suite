include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../vpc-network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/grafana?ref=gcp-apps-grafana-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location

  create_database = true
  database_config = {
    network_id = dependency.vpc.outputs.network_id
    tier       = "db-custom-1-3840" # small - dashboard metadata only
  }

  host_domains = {
    grafana = values.domains.grafana
  }

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
