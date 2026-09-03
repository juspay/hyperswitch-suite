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
  source = "../../../..//modules/composition/firewall-rules"
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

    bastion-egress-to-alloydb = {
      rules = [
        {
          name        = "allow-postgres"
          description = "Allow the bastion to reach AlloyDB over the Private Service Access range, for psql via an IAP SSH port-forward. Range, not instance IP, so it survives a cluster rebuild."
          direction   = "EGRESS"
          ranges      = ["10.214.0.0/16"]
          target_tags = ["bastion-host"]
          allow       = [{ protocol = "tcp", ports = ["5432"] }]
          log_config  = { metadata = "INCLUDE_ALL_METADATA" }
        },
      ]
    }

    bastion-egress-to-valkey = {
      rules = [
        {
          name        = "allow-valkey"
          description = "Allow the bastion to reach the Memorystore Valkey PSC endpoint in the memorystore subnet, for valkey-cli via an IAP SSH port-forward."
          direction   = "EGRESS"
          ranges      = ["10.2.74.0/24"]
          target_tags = ["bastion-host"]
          allow       = [{ protocol = "tcp", ports = ["6379"] }]
          log_config  = { metadata = "INCLUDE_ALL_METADATA" }
        },
      ]
    }

    envoy-to-istio-gke = {
      rules = [
        {
          name        = "allow-envoy-to-istio-ingress"
          description = "Allow the Envoy edge-proxy fleet to reach Istio's ingress gateway (and any GKE-hosted service) on the standard web ports"
          direction   = "INGRESS"
          source_tags = ["envoy-proxy"]
          target_tags = include.root.locals.gke_node_pool_target_tags
          allow       = [{ protocol = "tcp", ports = ["80", "443", "15021"] }]
        },
      ]
    }

    gke-to-squid-egress = {
      rules = [
        {
          name        = "allow-gke-to-squid-proxy"
          description = "Allow GKE pods (Hyperswitch app workloads) to reach Squid's internal LB for whitelisted egress"
          direction   = "INGRESS"
          ranges      = ["10.100.0.0/16", "10.2.32.0/20"]
          target_tags = ["squid-proxy"]
          allow       = [{ protocol = "tcp", ports = ["3128"] }]
        },
      ]
    }

    gke-egress-to-squid = {
      rules = [
        {
          name        = "allow-gke-to-squid-proxy"
          description = "Allow GKE nodes/pods to reach Squid's internal LB - the only egress path out of the cluster once default-deny-egress is on. Targets node tags (not pod ranges) since GCP firewall enforcement for VPC-native GKE applies at the node's vNIC regardless of whether the source is the node's own IP or a pod alias-range IP."
          direction   = "EGRESS"
          ranges      = ["10.2.77.0/24"]
          target_tags = include.root.locals.gke_node_pool_target_tags
          allow       = [{ protocol = "tcp", ports = ["3128"] }]
          log_config  = { metadata = "INCLUDE_ALL_METADATA" }
        },
      ]
    }

    gke-egress-to-alloydb = {
      rules = [
        {
          name        = "allow-postgres"
          description = "Allow GKE nodes/pods to reach AlloyDB (both the shared cluster and the locker's dedicated PCI-scoped one) over the Private Service Access range. Range, not instance IP, so it survives a cluster rebuild."
          direction   = "EGRESS"
          ranges      = ["10.214.0.0/16"]
          target_tags = include.root.locals.gke_node_pool_target_tags
          allow       = [{ protocol = "tcp", ports = ["5432"] }]
          log_config  = { metadata = "INCLUDE_ALL_METADATA" }
        },
      ]
    }

    squid-egress-to-internet = {
      rules = [
        {

          name        = "allow"
          description = "Allow Squid's own subnet to reach the internet on standard web ports - required for it to fulfill proxied requests. This is the designated proxy egress point, not a general internet allow."
          direction   = "EGRESS"
          ranges      = ["0.0.0.0/0"]
          target_tags = ["squid-proxy"]
          allow       = [{ protocol = "tcp", ports = ["80", "443"] }]
          log_config  = { metadata = "INCLUDE_ALL_METADATA" }
        },
      ]
    }
  }
}
