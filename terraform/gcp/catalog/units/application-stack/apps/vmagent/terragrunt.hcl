include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
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
  # TEMPORARY: module ref points at the module PR branch; repoint to the
  # gcp-apps-vmagent tag once that PR merges.
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/vmagent?ref=feat/gcp-vpc-network-gke-ingress-ilb-ip-module"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  cluster_name     = dependency.gke.outputs.cluster_name
  cluster_location = dependency.gke.outputs.location
}, try(values.cfg, {}))
