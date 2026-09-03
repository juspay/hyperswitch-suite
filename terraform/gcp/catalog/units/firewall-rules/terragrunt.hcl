# Cross-unit connectivity, assembled from the network tags the other units'
# modules set. Rules internal to one unit stay in that unit; only paths that
# span two units are declared here.
#
# APPLY LAST. This unit depends only on vpc-network, so Terragrunt is free to
# schedule it early — that is harmless (a rule may reference a tag no instance
# carries yet, which GCP accepts) but means the rules only take effect once
# the units they describe exist.
#
# Instance tags come from the modules, not from this file:
#   bastion-host  -> ["bastion-host", "iap-ssh"]
#   envoy-proxy   -> ["envoy-proxy",  "iap-ssh"]
#   squid-proxy   -> ["squid-proxy",  "iap-ssh"]
#
# The locker no longer runs a VM fleet (it is a GKE workload with an AlloyDB
# cluster reached over Private Service Access, which vpc-network's internal
# egress rule already covers), so it needs no rule here.

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    network_name = "mock-vpc"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/firewall-rules?ref=gcp-firewall-rules-v0.1.0"
}

inputs = {
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  network_name = dependency.vpc.outputs.network_name

  rules = {
    bastion-to-proxies = {
      rules = [
        {
          name        = "allow-bastion-ssh"
          description = "Bastion IAP SSH to the edge proxy fleets"
          direction   = "INGRESS"
          # GCP firewall rules cannot mix service-account and tag matching in
          # one rule (source_service_accounts conflicts with target_tags), so
          # source by the bastion's instance tag rather than its SA.
          source_tags = ["bastion-host"]
          target_tags = ["envoy-proxy", "squid-proxy"]
          allow       = [{ protocol = "tcp", ports = ["22"] }]
        },
      ]
    }

    gke-to-squid-egress = {
      rules = [
        {
          name        = "allow-gke-to-squid"
          description = "GKE nodes and pods to the Squid forward proxy"
          direction   = "INGRESS"
          # Range-based, not tag-based: the clients are GKE pods, which carry
          # no network tags. Keep in sync with squid-proxy's ilb_source_ranges
          # — both derive from the same two stack values.
          source_ranges = [
            "${values.vpc_cidr_prefix}.16.0/20",
            values.gke_pods_secondary_range_cidr,
          ]
          target_tags = ["squid-proxy"]
          allow       = [{ protocol = "tcp", ports = ["3128"] }]
        },
      ]
    }
  }
}
