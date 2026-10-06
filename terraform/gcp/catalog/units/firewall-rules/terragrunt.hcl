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
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/firewall-rules?ref=gcp-firewall-rules-v0.1.1"
}

inputs = merge({
  project_id   = include.root.locals.project_id
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  network_name = dependency.vpc.outputs.network_name

  ingress_rules = {
    bastion-to-proxies = {
      target_tags = ["envoy-proxy", "squid-proxy"]
      rules = [
        {
          name        = "allow-bastion-ssh"
          description = "Bastion IAP SSH to the edge proxy fleets"
          # GCP firewall rules cannot mix service-account and tag matching in
          # one rule (source_service_accounts conflicts with target_tags), so
          # source by the bastion's instance tag rather than its SA.
          source_tags = ["bastion-host"]
          allow       = [{ protocol = "tcp", ports = ["22"] }]
        },
      ]
    }

    gke-to-squid = {
      target_tags = ["squid-proxy"]
      rules = [
        {
          name        = "allow-gke-to-squid"
          description = "GKE nodes and pods to the Squid forward proxy"
          # Range-based, not tag-based: the clients are GKE pods, which carry
          # no network tags. Keep in sync with squid-proxy's ilb_source_ranges
          # — both derive from the same two stack values.
          ranges = [
            "${values.vpc_cidr_prefix}.16.0/20",
            values.gke_pods_secondary_range_cidr,
          ]
          allow = [{ protocol = "tcp", ports = ["3128"] }]
        },
      ]
    }

    gke-to-envoy-metrics = {
      target_tags = ["envoy-proxy"]
      rules = [
        {
          # Short name: the module prefixes it with
          # "<environment>-<project_name>-<rule-group-key>-", and the
          # longer, more descriptive name blew past GCP's 63-char cap.
          name        = "allow-vector-metrics"
          description = "GKE nodes and pods to the envoy-proxy fleet's Vector metrics port"
          ranges = [
            "${values.vpc_cidr_prefix}.16.0/20",
            values.gke_pods_secondary_range_cidr,
          ]
          allow = [{ protocol = "tcp", ports = ["9273"] }]
        },
      ]
    }

    # The global external Application LB (EXTERNAL_MANAGED) forwards client
    # traffic to the envoy fleet from Google front-end ranges, which are
    # different from its health-check ranges (130.211.0.0/22, 35.191.0.0/16 -
    # opened by the envoy-proxy module itself). Without this rule the backends
    # report HEALTHY but every client request returns 503.
    lb-to-envoy = {
      target_tags = ["envoy-proxy"]
      rules = [
        {
          name        = "allow-gfe-data-path"
          description = "Google front-end ranges to the envoy fleet's HTTP port (global external ALB data path)"
          ranges      = ["34.96.0.0/20", "34.127.192.0/18"]
          allow       = [{ protocol = "tcp", ports = ["8080"] }]
        },
      ]
    }
  }

  # vpc-network's default-deny egress rule (priority 65534) leaves only
  # internal ranges and the Google APIs endpoint reachable, so the paths that
  # must leave the VPC are opened here, per component.
  egress_rules = {
    # Squid is the only tier allowed to reach the internet. Its own domain
    # allowlist (allowedlist.txt) decides which hosts actually pass; without
    # this rule every CONNECT through Squid hangs until it times out, and
    # anything that depends on an outbound call (e.g. the router's deep health
    # check, connector calls) fails.
    #
    # Ports mirror the AWS squid_egress group (security-rules unit): 443 plus
    # the connector-specific 25443 (Redsys), 19585 (Archipel) and 8443. Plain
    # HTTP (80) is deliberately not opened, as on AWS.
    squid-to-internet = {
      target_tags = ["squid-proxy"]
      rules = [
        {
          name        = "allow-web-egress"
          description = "Squid forward proxy to the internet on 443 and the connector ports (Cloud NAT carries it out)"
          ranges      = ["0.0.0.0/0"]
          allow       = [{ protocol = "tcp", ports = ["443", "25443", "19585", "8443"] }]
        },
      ]
    }
  }
}, try(values.cfg, {}))
