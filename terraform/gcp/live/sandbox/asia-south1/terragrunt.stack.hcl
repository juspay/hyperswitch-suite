# =============================================================================
# Internal Hyperswitch GCP application stack
# =============================================================================
# The GKE cluster, the workloads that run on it, and the two data services
# those workloads need. Scoped deliberately: a unit exists here only if its
# module is published on `main`.
#
# Not in this stack (and why):
#   - load-balancer, cloud-cdn and the supporting composition units
#     (artifact-registry, bastion-host, cloud-dns, certificate-manager,
#     firewall-rules, pubsub, locker) — published, but out of scope.
#     NOTE: firewall-rules is what opens GKE -> squid egress; without it the
#     squid ILB is reachable only if the environment's rules already exist.
#   - Data-layer VM units (kafka, cassandra, clickhouse, opensearch, filestore)
#     and cloud-monitoring, gke-kubernetes-resources — no module on `main`.
#   - apps/decision-engine, apps/otel-collector, apps/ratelimiter — no module
#     on `main`; add them back once those land.
#
# `vpc-network` stays in the stack because every other unit depends on it,
# directly or through `gke`. Dropping it would leave the dependency graph
# dangling.
#
# Rendered into terraform/gcp/live/<env>/<region>/ by
# terraform/gcp/live/terragrunt.stack.hcl.
#
# Unit `path`s below are load-bearing — every unit's
# `dependency { config_path = "../..." }` is written against this exact
# layout. Renaming a path here breaks the dependency graph.
#
# `source` uses get_repo_root() rather than a relative path: this stack is
# itself fetched by path from the live layer, and a relative unit source loses
# its resolution context once copied into the generated tree.
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
# Phase 1 — Data services and cluster
# -----------------------------------------------------------------------------
# AlloyDB and Valkey are independent of each other and of gke; gke is the long
# pole, so start it first.

unit "alloydb" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/alloydb"
  path   = "alloydb"

  no_dot_terragrunt_stack = true

  # Omitted entirely rather than passed as null: a key present-but-null
  # defeats the unit's own try(values.X, <default>) fallback, because try()
  # rescues evaluation errors, not a successfully-resolved null.
  values = try(values.alloydb, null) != null ? { alloydb = values.alloydb } : {}
}

unit "memorystore-valkey" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/memorystore-valkey"
  path   = "memorystore-valkey"

  no_dot_terragrunt_stack = true

  values = try(values.valkey, null) != null ? { valkey = values.valkey } : {}
}

unit "gke" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/gke"
  path   = "application-stack/gke"

  no_dot_terragrunt_stack = true

  values = {
    machine_types = values.machine_types
  }
}

# -----------------------------------------------------------------------------
# Phase 2 — Platform apps
# -----------------------------------------------------------------------------
# gateway-controller and istio provide the ingress the workload apps attach to.

unit "gateway-controller" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/gateway-controller"
  path                    = "application-stack/apps/gateway-controller"
  no_dot_terragrunt_stack = true
}

unit "istio" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/istio"
  path   = "application-stack/apps/istio"

  no_dot_terragrunt_stack = true

  values = {
    domains = values.domains
  }
}

unit "argocd" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/argocd"
  path                    = "application-stack/apps/argocd"
  no_dot_terragrunt_stack = true
}

unit "external-secrets-operator" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/external-secrets-operator"
  path                    = "application-stack/apps/external-secrets-operator"
  no_dot_terragrunt_stack = true
}

# -----------------------------------------------------------------------------
# Phase 3 — Workload apps
# -----------------------------------------------------------------------------
unit "loki" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/loki"
  path                    = "application-stack/apps/loki"
  no_dot_terragrunt_stack = true
}

unit "vector" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/vector"
  path                    = "application-stack/apps/vector"
  no_dot_terragrunt_stack = true
}

unit "grafana" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/grafana"
  path   = "application-stack/apps/grafana"

  no_dot_terragrunt_stack = true

  values = {
    domains = values.domains
  }
}

unit "superposition" {
  source                  = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/superposition"
  path                    = "application-stack/apps/superposition"
  no_dot_terragrunt_stack = true
}

unit "hyperswitch" {
  source = "${get_repo_root()}/terraform/gcp/catalog/units/application-stack/apps/hyperswitch"
  path   = "application-stack/apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = {
    domains        = values.domains
    smtp_secret_id = values.smtp_secret_id
  }
}

# -----------------------------------------------------------------------------
# Phase 4 — Edge proxies
# -----------------------------------------------------------------------------
# Both depend only on vpc-network, so they can run alongside phases 1-3. Both
# need a pre-baked custom GCE image; terraform/gcp/packer/ has the definitions.

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

    # squid's ilb_source_ranges is derived from these two, exactly as
    # vpc-network derives the ranges themselves.
    vpc_cidr_prefix               = values.vpc_cidr_prefix
    gke_pods_secondary_range_cidr = values.gke_pods_secondary_range_cidr
  }
}
