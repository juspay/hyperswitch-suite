include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    network_name      = "mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "gke" {
  config_path = "../../gke"

  mock_outputs = {
    cluster_name   = "mock-cluster"
    endpoint       = "mock-endpoint"
    ca_certificate = "bW9jaw=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

locals {
  # Per-environment overrides, passed by the stack as this unit's `cfg` value.
  # Defaults below are what the live dev environment runs.
  cfg = try(values.cfg, {})
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/istio?ref=gcp-apps-istio-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  cluster_name           = dependency.gke.outputs.cluster_name
  cluster_endpoint       = dependency.gke.outputs.endpoint
  cluster_ca_certificate = dependency.gke.outputs.ca_certificate

  network      = dependency.vpc.outputs.network_self_link
  network_name = dependency.vpc.outputs.network_name

  create_gateway_static_ip = true
  create_firewall_rules    = true

  host_domains = {
    sandbox = [values.domains.api]
  }

  istio_namespace = try(local.cfg.istio_namespace, "istio-system")

  # Charts default to disabled: istio is installed through GitOps/Helm, and
  # this unit's job is the supporting GCP resources. Flip any of these to
  # { enabled = true } to let Terraform own that chart instead.
  istio_base    = try(local.cfg.istio_base, { enabled = false })
  istiod        = try(local.cfg.istiod, { enabled = false })
  istio_gateway = try(local.cfg.istio_gateway, { enabled = false })

  gateway_service_annotations = try(local.cfg.gateway_service_annotations, {})


  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
