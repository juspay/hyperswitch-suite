# =============================================================================
# Dev Hyperswitch GCP application stack
# =============================================================================
# The GKE cluster, the workloads that run on it, and the two data services
# those workloads need. Scoped deliberately: a unit exists here only if its
# module is published on `main`.
#
# Not in this stack (and why):
#   - load-balancer, cloud-cdn, cloud-dns, certificate-manager, pubsub —
#     published, but out of scope for this stack.
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
# `source` uses a git ref rather than a relative path: the stack is fetched by
# the live layer, and unit tags are the immutable release boundary. A relative
# path would lose resolution context once copied into the generated tree.
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 0 — Foundation
# -----------------------------------------------------------------------------
unit "vpc-network" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/vpc-network?ref=unit/gcp/vpc-network-v0.1.0-v2"
  path   = "vpc-network"

  no_dot_terragrunt_stack = true

  # subnet_cidrs / network_options are omitted rather than passed as null: a
  # key present-but-null defeats the unit's own try(values.X, <default>)
  # fallback, because try() rescues evaluation errors, not a resolved null.
  values = merge(
    {
      vpc_cidr_prefix                   = values.vpc_cidr_prefix
      gke_pods_secondary_range_cidr     = values.gke_pods_secondary_range_cidr
      gke_services_secondary_range_cidr = values.gke_services_secondary_range_cidr
    },
    try(values.subnet_cidrs, null) != null ? { subnet_cidrs = values.subnet_cidrs } : {},
    try(values.network_options, null) != null ? { network_options = values.network_options } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 1 — Data services and cluster
# -----------------------------------------------------------------------------
# AlloyDB and Valkey are independent of each other and of gke; gke is the long
# pole, so start it first.

unit "alloydb" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/alloydb?ref=unit/gcp/alloydb-v0.1.0-v2"
  path   = "alloydb"

  no_dot_terragrunt_stack = true

  # Omitted entirely rather than passed as null: a key present-but-null
  # defeats the unit's own try(values.X, <default>) fallback, because try()
  # rescues evaluation errors, not a successfully-resolved null.
  values = try(values.alloydb, null) != null ? { alloydb = values.alloydb } : {}
}

unit "memorystore-valkey" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/memorystore-valkey?ref=unit/gcp/memorystore-valkey-v0.1.0-v2"
  path   = "memorystore-valkey"

  no_dot_terragrunt_stack = true

  values = try(values.valkey, null) != null ? { valkey = values.valkey } : {}
}

unit "gke" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/gke?ref=unit/gcp/gke-v0.1.0-v2"
  path   = "application-stack/gke"

  no_dot_terragrunt_stack = true

  values = merge(
    { machine_types = values.machine_types },
    try(values.gke_master_ipv4_cidr_block, null) != null ? { gke_master_ipv4_cidr_block = values.gke_master_ipv4_cidr_block } : {},
    try(values.gke_deletion_protection, null) != null ? { gke_deletion_protection = values.gke_deletion_protection } : {},
    try(values.unit_config.gke, null) != null ? { cfg = values.unit_config.gke } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 2 — Platform apps
# -----------------------------------------------------------------------------
# gateway-controller and istio provide the ingress the workload apps attach to.

unit "gateway-controller" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/gateway-controller?ref=unit/gcp/gateway-controller-v0.1.0-v2"
  path                    = "application-stack/apps/gateway-controller"
  no_dot_terragrunt_stack = true
}

unit "istio" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/istio?ref=unit/gcp/istio-v0.1.0-v2"
  path   = "application-stack/apps/istio"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      domains = values.domains
    },
    try(values.unit_config.istio, null) != null ? { cfg = values.unit_config.istio } : {},
  )
}

unit "argocd" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/argocd?ref=unit/gcp/argocd-v0.1.0-v2"
  path                    = "application-stack/apps/argocd"
  no_dot_terragrunt_stack = true

  values = try(values.unit_config.argocd, null) != null ? { cfg = values.unit_config.argocd } : {}
}

unit "external-secrets-operator" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/external-secrets-operator?ref=unit/gcp/external-secrets-operator-v0.1.0-v2"
  path                    = "application-stack/apps/external-secrets-operator"
  no_dot_terragrunt_stack = true

  values = try(values.unit_config.external_secrets_operator, null) != null ? { cfg = values.unit_config.external_secrets_operator } : {}
}

# -----------------------------------------------------------------------------
# Phase 3 — Workload apps
# -----------------------------------------------------------------------------
unit "loki" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/loki?ref=unit/gcp/loki-v0.1.0-v2"
  path                    = "application-stack/apps/loki"
  no_dot_terragrunt_stack = true

  values = try(values.unit_config.loki, null) != null ? { cfg = values.unit_config.loki } : {}
}

unit "vector" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/vector?ref=unit/gcp/vector-v0.1.0-v2"
  path                    = "application-stack/apps/vector"
  no_dot_terragrunt_stack = true

  values = try(values.unit_config.vector, null) != null ? { cfg = values.unit_config.vector } : {}
}

unit "grafana" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/grafana?ref=unit/gcp/grafana-v0.1.0-v2"
  path   = "application-stack/apps/grafana"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      domains = values.domains
    },
    try(values.unit_config.grafana, null) != null ? { cfg = values.unit_config.grafana } : {},
  )
}

unit "superposition" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/superposition?ref=unit/gcp/superposition-v0.1.0-v2"
  path                    = "application-stack/apps/superposition"
  no_dot_terragrunt_stack = true

  values = try(values.unit_config.superposition, null) != null ? { cfg = values.unit_config.superposition } : {}
}

unit "hyperswitch" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/application-stack/apps/hyperswitch?ref=unit/gcp/hyperswitch-v0.1.0-v2"
  path   = "application-stack/apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      domains        = values.domains
      smtp_secret_id = values.smtp_secret_id
    },
    try(values.unit_config.hyperswitch, null) != null ? { cfg = values.unit_config.hyperswitch } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 4 — Edge proxies
# -----------------------------------------------------------------------------
# Both depend only on vpc-network, so they can run alongside phases 1-3. Both
# need a pre-baked custom GCE image; terraform/gcp/packer/ has the definitions.

unit "envoy-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/envoy-proxy?ref=unit/gcp/envoy-proxy-v0.1.0-v2"
  path   = "envoy-proxy"

  no_dot_terragrunt_stack = true

  # envoy is optional (values.envoy is itself optional inside the unit) - a
  # consumer that omits it entirely gets no envoy.yaml uploaded at all
  # (custom_startup_script still renders, but has nothing to fetch). Set it
  # to get the unit's default single-cluster config, or add
  # values.envoy.assets_dir to point at a private config/envoy.yaml.tftpl +
  # templates/startup.sh instead.
  values = {
    custom_images = values.custom_images
    domains       = values.domains
    envoy         = try(values.envoy, null)
  }
}

unit "squid-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/squid-proxy?ref=unit/gcp/squid-proxy-v0.1.0-v2"
  path   = "squid-proxy"

  no_dot_terragrunt_stack = true

  values = {
    custom_images = values.custom_images

    # squid's ilb_source_ranges is derived from these two, exactly as
    # vpc-network derives the ranges themselves.
    vpc_cidr_prefix               = values.vpc_cidr_prefix
    gke_pods_secondary_range_cidr = values.gke_pods_secondary_range_cidr

    # Optional - set values.squid.assets_dir to point at a private
    # config/{squid.conf,allowedlist.txt} + templates/startup.sh directory
    # instead of the unit's own bundled defaults.
    squid = try(values.squid, {})
  }
}

# -----------------------------------------------------------------------------
# Phase 5 — Supporting infrastructure
# -----------------------------------------------------------------------------
unit "artifact-registry" {
  source                  = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/artifact-registry?ref=unit/gcp/artifact-registry-v0.1.0-v2"
  path                    = "artifact-registry"
  no_dot_terragrunt_stack = true
}

unit "bastion-host" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/bastion-host?ref=unit/gcp/bastion-host-v0.1.0-v2"
  path   = "bastion-host"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      bastion_iap_members = values.bastion_iap_members
      machine_types       = values.machine_types
    },
    try(values.unit_config.bastion_host, null) != null ? { cfg = values.unit_config.bastion_host } : {},
  )
}

# Data tier and identity for the card vault. The vault itself runs on GKE via
# Helm, so this depends on both vpc-network and gke.
unit "locker" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/locker?ref=unit/gcp/locker-v0.1.0-v2"
  path   = "locker"

  no_dot_terragrunt_stack = true

  values = try(values.locker, null) != null ? { locker = values.locker } : {}
}

# -----------------------------------------------------------------------------
# Phase 6 — Firewall rules (apply last)
# -----------------------------------------------------------------------------
# Cross-unit connectivity assembled from the other units' instance tags. It
# depends only on vpc-network, so Terragrunt may schedule it early — harmless,
# but the rules only bite once the units they describe exist.
unit "firewall-rules" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/firewall-rules?ref=unit/gcp/firewall-rules-v0.1.0-v2"
  path   = "firewall-rules"

  no_dot_terragrunt_stack = true

  values = {
    # gke-to-squid-egress derives its source ranges from these, exactly as
    # squid-proxy derives ilb_source_ranges and vpc-network derives the ranges
    # themselves. All three must agree.
    vpc_cidr_prefix               = values.vpc_cidr_prefix
    gke_pods_secondary_range_cidr = values.gke_pods_secondary_range_cidr
  }
}
