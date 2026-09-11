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

inputs = merge({
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

  # ---------------------------------------------------------------------
  # Config pipeline
  # ---------------------------------------------------------------------
  # Without these two inputs the module uploads nothing to the config bucket,
  # the VM runs the stock Ubuntu squid.conf baked into the image, and that
  # config ends in `http_access deny all`. Squid then accepts the TCP
  # connection and silently drops the CONNECT, so clients hang for their full
  # timeout instead of getting a fast 403 - indistinguishable from a network
  # fault. See templates/startup.sh for the full explanation.
  #
  # get_terragrunt_dir() (not get_repo_root()): `terragrunt stack generate`
  # copies this unit's non-HCL files (config/, templates/) alongside the
  # generated terragrunt.hcl, so these paths resolve for any consumer.
  #
  # squid_config_content has a working default (config/squid.conf); the
  # allowlist's default is DELIBERATELY minimal (Google's own API domains
  # only, see config/allowedlist.txt) since a real deployment's allowlist is
  # inherently environment-specific. Point values.squid.allowlist_file at a
  # private file to extend it, or override squid_allowlist_content wholesale
  # via values.cfg for anything more than a file swap.
  squid_config_content    = file("${get_terragrunt_dir()}/config/squid.conf")
  squid_allowlist_content = file(try(values.squid.allowlist_file, "${get_terragrunt_dir()}/config/allowedlist.txt"))

  custom_startup_script = file("${get_terragrunt_dir()}/templates/startup.sh")

  labels = merge({
    environment = include.root.locals.environment.short
    project     = include.root.locals.project_name
    managed_by  = "terraform"
  }, try(values.common_labels, {}))
}, try(values.cfg, {}))
