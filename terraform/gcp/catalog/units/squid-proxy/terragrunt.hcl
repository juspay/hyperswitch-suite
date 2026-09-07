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

  # Required since #309, with no default: the underlying lb-internal module
  # falls back to 0.0.0.0/0 when both source_ip_ranges and source_tags are
  # unset. Squid's clients are GKE pods, which carry no network tags to match
  # on, so this has to be IP-range based.
  #
  # Derived from the same stack values ../vpc-network builds its GKE ranges
  # from, so the two cannot drift: the gke-nodes subnet CIDR and the pods
  # secondary range.
  ilb_source_ranges = [
    "${values.vpc_cidr_prefix}.16.0/20",
    values.gke_pods_secondary_range_cidr,
  ]

  min_replicas = 2
  max_replicas = 6

  labels = {
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }
}
