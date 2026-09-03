# =============================================================================
# Internal Hyperswitch GCP stack
# =============================================================================
# Full single-region composition of the GCP catalog for internal environments
# (sandbox / dev / pre-prod / prod). This stack creates its own VPC: no unit
# below is passed a pre-existing network, so every VPC-consuming unit reads
# its networking inputs from the `vpc-network` unit created here.
#
# Rendered into terraform/gcp/live/<env>/<region>/ by
# terraform/gcp/live/terragrunt.stack.hcl.
#
# Unit `path`s below are load-bearing — every unit's
# `dependency { config_path = "../..." }` is written against this exact
# layout. Renaming a path here breaks the dependency graph.
#
# `source` uses get_repo_root() rather than a relative path: this stack is
# itself fetched by path from the live layer, and a relative unit source
# loses its resolution context once copied into the generated tree.
# get_repo_root() re-resolves correctly at every nesting level.
#
#   Phase 0 — Foundation:        vpc-network
#   Phase 1 — Data + compute:    cloud-sql, memorystore, artifact-registry,
#                                filestore, pubsub, cloud-dns,
#                                certificate-manager, bastion-host, kafka,
#                                cassandra, clickhouse, opensearch, locker, gke
#   Phase 2 — Cluster resources: gke-kubernetes-resources
#   Phase 3 — Platform apps:     apps/{gateway-controller,istio,argocd,
#                                external-secrets-operator,otel-collector}
#   Phase 4 — Workload apps:     apps/{loki,vector,grafana,superposition,
#                                decision-engine,ratelimiter,hyperswitch}
#   Phase 5 — Edge:              load-balancer, cloud-cdn, envoy-proxy,
#                                squid-proxy, cloud-monitoring
#   Phase 6 — Firewall rules:    firewall-rules (apply last)
#
# 34 units total. Terragrunt derives the real ordering from each unit's
# `dependency` blocks, not from the phase banners below.
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 0 — Foundation
# -----------------------------------------------------------------------------
unit "vpc-network" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/vpc-network"
  path   = "vpc-network"

  no_dot_terragrunt_stack = true

  values = {
    vpc_cidr_prefix                   = values.vpc_cidr_prefix
    gke_pods_secondary_range_cidr     = values.gke_pods_secondary_range_cidr
    gke_services_secondary_range_cidr = values.gke_services_secondary_range_cidr
  }
}

# -----------------------------------------------------------------------------
# Phase 1 — Data Layer + Compute Core
# -----------------------------------------------------------------------------
unit "cloud-sql" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/cloud-sql"
  path                    = "cloud-sql"
  no_dot_terragrunt_stack = true
}

unit "memorystore" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/memorystore"
  path                    = "memorystore"
  no_dot_terragrunt_stack = true
}

unit "artifact-registry" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/artifact-registry"
  path                    = "artifact-registry"
  no_dot_terragrunt_stack = true
}

unit "filestore" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/filestore"
  path                    = "filestore"
  no_dot_terragrunt_stack = true
}

unit "pubsub" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/pubsub"
  path                    = "pubsub"
  no_dot_terragrunt_stack = true
}

unit "cloud-dns" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/cloud-dns"
  path                    = "cloud-dns"
  no_dot_terragrunt_stack = true
}

unit "certificate-manager" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/certificate-manager"
  path   = "certificate-manager"

  no_dot_terragrunt_stack = true

  values = {
    domains = values.domains
  }
}

unit "bastion-host" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/bastion-host"
  path   = "bastion-host"

  no_dot_terragrunt_stack = true

  values = {
    bastion_iap_members = values.bastion_iap_members
    machine_types       = values.machine_types
  }
}

unit "kafka" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/kafka"
  path   = "kafka"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "cassandra" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/cassandra"
  path   = "cassandra"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "clickhouse" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/clickhouse"
  path   = "clickhouse"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "opensearch" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/opensearch"
  path   = "opensearch"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "locker" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/locker"
  path   = "locker"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "gke" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/gke"
  path   = "gke"

  no_dot_terragrunt_stack = true

  values = {
    machine_types = values.machine_types
  }
}

# -----------------------------------------------------------------------------
# Phase 2 — Cluster Resources
# -----------------------------------------------------------------------------
unit "gke-kubernetes-resources" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/gke-kubernetes-resources"
  path                    = "gke-kubernetes-resources"
  no_dot_terragrunt_stack = true
}

# -----------------------------------------------------------------------------
# Phase 3 — Platform Apps
# -----------------------------------------------------------------------------
unit "gateway-controller" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/gateway-controller"
  path                    = "apps/gateway-controller"
  no_dot_terragrunt_stack = true
}

unit "istio" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/apps/istio"
  path   = "apps/istio"

  no_dot_terragrunt_stack = true

  values = {
    domains = values.domains
  }
}

unit "argocd" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/argocd"
  path                    = "apps/argocd"
  no_dot_terragrunt_stack = true
}

unit "external-secrets-operator" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/external-secrets-operator"
  path                    = "apps/external-secrets-operator"
  no_dot_terragrunt_stack = true
}

unit "otel-collector" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/otel-collector"
  path                    = "apps/otel-collector"
  no_dot_terragrunt_stack = true
}

# -----------------------------------------------------------------------------
# Phase 4 — Workload Apps
# -----------------------------------------------------------------------------
unit "loki" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/loki"
  path                    = "apps/loki"
  no_dot_terragrunt_stack = true
}

unit "vector" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/vector"
  path                    = "apps/vector"
  no_dot_terragrunt_stack = true
}

unit "grafana" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/apps/grafana"
  path   = "apps/grafana"

  no_dot_terragrunt_stack = true

  values = {
    domains = values.domains
  }
}

unit "superposition" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/apps/superposition"
  path                    = "apps/superposition"
  no_dot_terragrunt_stack = true
}

unit "decision-engine" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/apps/decision-engine"
  path   = "apps/decision-engine"

  no_dot_terragrunt_stack = true

  values = {
    smtp_secret_id = values.smtp_secret_id
  }
}

unit "ratelimiter" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/apps/ratelimiter"
  path   = "apps/ratelimiter"

  no_dot_terragrunt_stack = true

  values = {
    gke_pods_secondary_range_cidr = values.gke_pods_secondary_range_cidr
  }
}

unit "hyperswitch" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/apps/hyperswitch"
  path   = "apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = {
    domains        = values.domains
    smtp_secret_id = values.smtp_secret_id
  }
}

# -----------------------------------------------------------------------------
# Phase 5 — Edge
# -----------------------------------------------------------------------------
unit "load-balancer" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/load-balancer"
  path                    = "load-balancer"
  no_dot_terragrunt_stack = true
}

unit "cloud-cdn" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/cloud-cdn"
  path                    = "cloud-cdn"
  no_dot_terragrunt_stack = true
}

unit "envoy-proxy" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/envoy-proxy"
  path   = "envoy-proxy"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
    domains       = values.domains
  }
}

unit "squid-proxy" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/squid-proxy"
  path   = "squid-proxy"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images
  }
}

unit "cloud-monitoring" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/cloud-monitoring"
  path   = "cloud-monitoring"

  no_dot_terragrunt_stack = true

  values = {
    alert_notification_email = values.alert_notification_email
  }
}

# -----------------------------------------------------------------------------
# Phase 6 — Firewall Rules (last — depends on almost everything)
# -----------------------------------------------------------------------------
unit "firewall-rules" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/firewall-rules"
  path                    = "firewall-rules"
  no_dot_terragrunt_stack = true
}
