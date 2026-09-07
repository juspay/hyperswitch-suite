# envoy_image needs a pre-baked custom image with Envoy installed - see
# values.custom_images in the stack.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { incoming-envoy = "projects/mock/regions/asia-south1/subnetworks/mock-incoming-envoy" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/envoy-proxy?ref=gcp-envoy-proxy-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["incoming-envoy"]

  envoy_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.envoy}"

  min_replicas = 2
  max_replicas = 6

  managed_ssl_certificate_domains = [values.domains.api]

  enable_cloud_armor   = true
  enable_mtls_listener = false

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
