# Deployed LAST - the same role composition/security-rules plays on the AWS
# side. Rules that are entirely internal to one unit stay in that unit
# (e.g. clickhouse's own internal LB health-check rule); only cross-unit
# connectivity is assembled here, from every other unit's outputs.
#
# Starts with just the bastion -> data-stack SSH path; extend as more
# cross-unit connectivity is needed (e.g. envoy-proxy -> GKE nodes once
# node_pools_tags are set on ../gke).

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
    bastion-to-locker = {
      rules = [
        {
          name        = "allow-bastion-ssh"
          description = "Allow bastion IAP SSH to the locker server fleet"
          direction   = "INGRESS"
          # GCP firewall rules can't mix service-account and tag matching in
          # one rule (source_service_accounts conflicts with target_tags) -
          # source by the bastion instance tag instead of its SA.
          source_tags = ["bastion-host"]
          target_tags = ["locker-node"]
          allow       = [{ protocol = "tcp", ports = ["22"] }]
        },
      ]
    }

    bastion-to-data-stack = {
      rules = [
        {
          name        = "allow-bastion-ssh"
          description = "Allow bastion IAP SSH to the data-stack VM fleets"
          direction   = "INGRESS"
          source_tags = ["bastion-host"]
          target_tags = [
            "kafka-broker",
            "kafka-controller",
            "cassandra-node",
            "clickhouse-server",
            "clickhouse-keeper",
            "opensearch-node",
          ]
          allow = [{ protocol = "tcp", ports = ["22"] }]
        },
      ]
    }
  }
}
