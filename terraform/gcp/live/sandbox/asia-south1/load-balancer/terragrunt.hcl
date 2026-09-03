# Utility module for services that need their own dedicated LB outside of
# envoy-proxy's built-in one (e.g. an internal admin tool). No backends
# wired by default - this is a template; fill in `backends` /
# `internal_backends` for a real service before applying.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/load-balancer?ref=gcp-load-balancer-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  name_override = "utils"
  internal      = false

  network = dependency.vpc.outputs.network_self_link

  ssl = false # no domain/certificate wired yet - see ../certificate-manager

  # TEMPLATE - no backends configured. Fill in before applying:
  # backends = {
  #   default = {
  #     groups       = [{ group = "<instance-group-self-link>" }]
  #     health_check = { request_path = "/health", port = 8080 }
  #     log_config   = { enable = true, sample_rate = 1.0 }
  #   }
  # }
  backends = {}

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}
