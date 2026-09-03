# Private zone for internal service discovery within the VPC. A public zone
# for the real domain should be added once that domain is decided - left
# commented below as a template.

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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/cloud-dns?ref=gcp-cloud-dns-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  zone_name = "${include.root.locals.project_name}-${include.root.locals.environment.short}-internal"
  domain    = "${include.root.locals.environment.short}.hyperswitch.internal."
  type      = "private"

  private_visibility_config_networks = [dependency.vpc.outputs.network_self_link]

  recordsets = []

  labels = {
    environment = include.root.locals.environment.short
    managed_by  = "terraform"
  }
}

# --- Public zone template (uncomment and set the real domain) --------------
# See ../apps/istio and ../envoy-proxy for where the resulting IPs come from.
#
# inputs = {
#   ...
#   zone_name     = "${include.root.locals.project_name}-${include.root.locals.environment.short}-public"
#   domain        = "${values.domains.api}."
#   type          = "public"
#   enable_dnssec = true
#   recordsets = [
#     { name = "api", type = "A", ttl = 300, records = ["X.X.X.X"] },
#   ]
# }
