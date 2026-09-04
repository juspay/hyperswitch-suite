include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    network_id = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
    cluster_name   = "mock-cluster"
    location       = "asia-south1"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  # Per-environment overrides, passed by the stack as this unit's `cfg` value.
  # Defaults below are what the live dev environment runs.
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/grafana?ref=gcp-apps-grafana-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name = dependency.gke.outputs.cluster_name

  # Required by the module since #310 — the Kubernetes/Helm provider is

  # configured from these rather than from a kubeconfig lookup.

  cluster_endpoint = dependency.gke.outputs.endpoint

  cluster_ca_certificate = dependency.gke.outputs.ca_certificate
  cluster_location       = dependency.gke.outputs.location

  create_database = true
  database_config = {
    network_id = dependency.vpc.outputs.network_id
    tier       = "db-custom-1-3840" # small - dashboard metadata only
  }

  host_domains = {
    grafana = values.domains.grafana
  }

  k8s_namespace            = try(local.cfg.k8s_namespace, "monitoring")
  k8s_service_account_name = try(local.cfg.k8s_service_account_name, "grafana")
  use_existing_k8s_sa      = try(local.cfg.use_existing_k8s_sa, false)

  additional_project_roles = try(local.cfg.additional_project_roles, [
    "roles/monitoring.viewer",
    "roles/logging.viewer",
  ])


  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
