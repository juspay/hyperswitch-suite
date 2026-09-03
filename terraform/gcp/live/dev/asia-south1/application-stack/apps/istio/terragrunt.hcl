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
    network_self_link = "https://www.googleapis.com/compute/v1/projects/mock/global/networks/mock-vpc"
    network_name      = "mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "../../../../../../modules/application-resources/istio"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name = dependency.gke.outputs.cluster_name

  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  network      = dependency.vpc.outputs.network_self_link
  network_name = dependency.vpc.outputs.network_name

  istio_namespace = "istio-system"

  istio_base    = { enabled = false }
  istiod        = { enabled = false }
  istio_gateway = { enabled = false }

  create_gateway_static_ip    = false
  gateway_service_annotations = {}

  create_firewall_rules = false

  host_domains = {
    dev = include.root.locals.domains
  }

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    component   = "istio"
    managed_by  = "terraform"
  }
}
