# =============================================================================
# Dev Hyperswitch stack
# =============================================================================
# Full-parity single-region composition for internal dev / pre-prod / prod
# environments. Unlike [self-host path removed] (BYO-VPC, self-host), this stack
# creates its own VPC: no unit below is passed `vpc_id` / `*_subnet_ids`, so
# every VPC-consuming unit's `dependency.vpc { enabled = ... }` toggle falls
# through to the `vpc-network` unit created here (see e.g.
# units/database/terragrunt.hcl:11-13,41).
#
# Rendered into terraform/aws/live/<env>/<region>/ by
# terraform/aws/live/terragrunt.stack.hcl. Unit `path`s below are load-bearing
# — every unit's `dependency { config_path = "../..." }` is written against
# this exact layout; renaming a path here breaks the dependency graph.
#
#   Phase 1 — Network & DNS:    vpc-network, route53, acm
#   Phase 2 — Data layer:       database, elasticache, efs, kafka, locker
#   Phase 3 — Proxies & access: squid-proxy, envoy-proxy, jump-host
#   Phase 4 — Compute:          application-stack/eks-01
#   Phase 5 — K8s resources:    application-stack/{eks-resources,utils-load-balancer}
#   Phase 6 — Apps:             application-stack/apps/*
#   Phase 7 — Security rules:   security-rules (apply last)
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1 — Network & DNS
# -----------------------------------------------------------------------------
unit "vpc-network" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/vpc-network?ref=unit/aws/vpc-network-v0.1.11-v1"
  path   = "vpc-network"

  no_dot_terragrunt_stack = true

  # merge() rather than try(values.X, null): a key present-but-null in a
  # unit's values map defeats that unit's own try(values.X, <default>)
  # fallback, because try() only rescues evaluation errors, not a
  # successfully-resolved null. Omitting the key entirely lets the unit's
  # default apply.
  values = merge(
    { vpc_cidr_prefix = values.vpc_cidr_prefix },
    try(values.single_nat_gateway, null) != null ? { single_nat_gateway = values.single_nat_gateway } : {},
  )
}

unit "route53" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/route53?ref=unit/aws/route53-v0.1.0-v1"
  path   = "route53"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.public_zone_records, null) != null ? { public_zone_records = values.public_zone_records } : {},
    try(values.internal_zone_records, null) != null ? { internal_zone_records = values.internal_zone_records } : {},
  )
}

unit "acm" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/acm?ref=unit/aws/acm-v0.1.0-v1"
  path   = "acm"

  no_dot_terragrunt_stack = true

  values = {
    base_domain = values.base_domain
  }
}

# -----------------------------------------------------------------------------
# Phase 2 — Data layer
# -----------------------------------------------------------------------------
unit "database" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/database?ref=unit/aws/database-v0.1.6-v1"
  path   = "database"

  no_dot_terragrunt_stack = true

  values = {
    db_instance_class = try(values.db_instance_class, null)
    engine_version    = try(values.db_engine_version, null)
  }
}

unit "elasticache" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/elasticache?ref=unit/aws/elasticache-v0.1.5-v1"
  path   = "elasticache"

  no_dot_terragrunt_stack = true

  values = {
    cache_node_type = try(values.cache_node_type, null)
  }
}

unit "efs" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/efs?ref=unit/aws/efs-v0.1.1-v1"
  path   = "efs"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "kafka" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/kafka?ref=unit/aws/kafka-v0.1.3-v1"
  path   = "kafka"

  no_dot_terragrunt_stack = true

  values = {
    broker_ami_id     = try(values.kafka_broker_ami_id, null)
    controller_ami_id = try(values.kafka_controller_ami_id, null)
  }
}

unit "locker" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/locker?ref=unit/aws/locker-v0.2.8-v1"
  path   = "locker"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.db_engine_version, null) != null ? { engine_version = values.db_engine_version } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 3 — Proxies & access
# -----------------------------------------------------------------------------
unit "squid-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/squid-proxy?ref=unit/aws/squid-proxy-v0.1.4-v1"
  path   = "squid-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

unit "envoy-proxy" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/envoy-proxy?ref=unit/aws/envoy-proxy-v0.3.2-v1"
  path   = "envoy-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      ami_id                = values.ami_id
      virtual_hosts_domains = values.virtual_hosts_domains
    },
    try(values.base_domain, null) != null ? { base_domain = values.base_domain } : {},
    try(values.cn_base_domain, null) != null ? { cn_base_domain = values.cn_base_domain } : {},
    try(values.opensearch_endpoint, null) != null ? { opensearch_endpoint = values.opensearch_endpoint } : {},
    try(values.opensearch_region, null) != null ? { opensearch_region = values.opensearch_region } : {},
    try(values.envoy_lb_internal, null) != null ? { lb_internal = values.envoy_lb_internal } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

unit "jump-host" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/jump-host?ref=unit/aws/jump-host-v0.2.1-v1"
  path   = "jump-host"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 4 — Compute
# -----------------------------------------------------------------------------
unit "eks-01" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/eks-01"
  path   = "application-stack/eks-01"

  no_dot_terragrunt_stack = true

  values = {
    cluster_version    = try(values.eks_version, null)
    admin_sso_role_arn = values.admin_role_arn
    admin_access_cidrs = values.admin_access_cidrs
    default_ami_id     = try(values.eks_ami_id, null)

    system_nodes = {
      desired_size   = try(values.system_nodes_desired_size, 1)
      instance_types = values.eks_instance_types
    }

    generic_compute = {
      desired_size   = try(values.generic_compute_desired_size, 2)
      min_size       = try(values.generic_compute_min_size, 1)
      instance_types = values.eks_instance_types
    }
  }
}

# -----------------------------------------------------------------------------
# Phase 5 — Kubernetes resources
# -----------------------------------------------------------------------------
unit "eks-resources" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/eks-resources?ref=unit/aws/eks-resources-v0.1.3-v1"
  path   = "application-stack/eks-resources"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "utils-load-balancer" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/utils-load-balancer?ref=unit/aws/utils-load-balancer-v0.1.1-v1"
  path   = "application-stack/utils-load-balancer"

  no_dot_terragrunt_stack = true

  values = {}
}

# -----------------------------------------------------------------------------
# Phase 6 — Apps (Kubernetes workloads)
# -----------------------------------------------------------------------------
unit "alb-controller" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/alb-controller?ref=unit/aws/alb-controller-v0.1.2-v1"
  path   = "application-stack/apps/alb-controller"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "external-secrets" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/external-secrets?ref=unit/aws/external-secrets-v0.1.1-v1"
  path   = "application-stack/apps/external-secrets"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "istio" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/istio?ref=unit/aws/istio-v0.1.4-v1"
  path   = "application-stack/apps/istio"

  no_dot_terragrunt_stack = true

  values = {
    host_domains = values.istio_host_domains
  }
}

unit "otel" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/otel?ref=unit/aws/otel-v0.1.0-v1"
  path   = "application-stack/apps/otel"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "vector-dr" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/vector-dr?ref=unit/aws/vector-dr-v0.1.1-v1"
  path   = "application-stack/apps/vector-dr"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "loki" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/loki?ref=unit/aws/loki-v0.1.3-v1"
  path   = "application-stack/apps/loki"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "grafana" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/grafana?ref=unit/aws/grafana-v0.1.3-v1"
  path   = "application-stack/apps/grafana"

  no_dot_terragrunt_stack = true

  values = {
    base_domain = values.base_domain
  }
}

unit "ratelimiter" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/ratelimiter?ref=unit/aws/ratelimiter-v0.1.0-v1"
  path   = "application-stack/apps/ratelimiter"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "hyperswitch" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/hyperswitch?ref=unit/aws/hyperswitch-v0.1.1-v1"
  path   = "application-stack/apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = {
    ses_email_role_arn = try(values.ses_email_role_arn, null)
  }
}

unit "decision-engine" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/decision-engine?ref=unit/aws/decision-engine-v0.1.2-v1"
  path   = "application-stack/apps/decision-engine"

  no_dot_terragrunt_stack = true

  values = {
    ses_email_role_arn = try(values.ses_email_role_arn, null)
  }
}

unit "superposition" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/application-stack/apps/superposition?ref=unit/aws/superposition-v0.1.7-v1"
  path   = "application-stack/apps/superposition"

  no_dot_terragrunt_stack = true

  values = {
    base_domain = values.base_domain
  }
}

# -----------------------------------------------------------------------------
# Phase 7 — Security rules (apply last)
# -----------------------------------------------------------------------------
unit "security-rules" {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/catalog/units/security-rules?ref=unit/aws/security-rules-v0.2.1-v1"
  path   = "security-rules"

  no_dot_terragrunt_stack = true

  values = {
    # No vpc_id -> local.has_vpc_network = true -> reads the created vpc-network unit.
    # Every enable_* toggle is left at its catalog default (true) for full parity;
    # only the internal-only, not-yet-modeled components stay off by default:
    #   enable_encryption_service, enable_auth_proxy, enable_wazuh_endpoints
  }
}
