# squid_image needs a pre-baked custom image with Squid installed - see
# values.custom_images in the stack. Outbound internet access is provided by
# the Cloud Router + Cloud NAT already created in ../vpc-network.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_self_link = "projects/mock/global/networks/mock-vpc"
    subnets_by_tier   = { outgoing-proxy = "projects/mock/regions/asia-south1/subnetworks/mock-outgoing-proxy" }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/squid-proxy?ref=gcp-squid-proxy-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  network          = dependency.vpc.outputs.network_self_link
  proxy_subnetwork = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]
  lb_subnetwork    = dependency.vpc.outputs.subnets_by_tier["outgoing-proxy"]

  squid_image = "projects/${include.root.locals.project_id}/global/images/${values.custom_images.squid}"

  min_replicas = 2
  max_replicas = 6

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
