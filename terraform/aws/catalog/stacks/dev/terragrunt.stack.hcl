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
  source = "${get_repo_root()}/terraform/aws/catalog/units/vpc-network"
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
  source = "${get_repo_root()}/terraform/aws/catalog/units/route53"
  path   = "route53"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.public_zone_records, null) != null ? { public_zone_records = values.public_zone_records } : {},
    try(values.internal_zone_records, null) != null ? { internal_zone_records = values.internal_zone_records } : {},
  )
}

unit "acm" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/acm"
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
  source = "${get_repo_root()}/terraform/aws/catalog/units/database"
  path   = "database"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      db_instance_class = try(values.db_instance_class, null)
      engine_version    = try(values.db_engine_version, null)
    },
    try(values.db_backup_retention_period, null) != null ? { backup_retention_period = values.db_backup_retention_period } : {},
  )
}

unit "elasticache" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/elasticache"
  path   = "elasticache"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      cache_node_type = try(values.cache_node_type, null)
    },
    try(values.cache_num_node_groups, null) != null ? { cache_num_node_groups = values.cache_num_node_groups } : {},
    try(values.cache_replicas_per_node_group, null) != null ? { cache_replicas_per_node_group = values.cache_replicas_per_node_group } : {},
    try(values.cache_node_group_configuration, null) != null ? { cache_node_group_configuration = values.cache_node_group_configuration } : {},
  )
}

unit "efs" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/efs"
  path   = "efs"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "kafka" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/kafka"
  path   = "kafka"

  no_dot_terragrunt_stack = true

  values = {
    broker_ami_id     = try(values.kafka_broker_ami_id, null)
    controller_ami_id = try(values.kafka_controller_ami_id, null)
  }
}

unit "locker" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/locker"
  path   = "locker"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.db_engine_version, null) != null ? { engine_version = values.db_engine_version } : {},
    try(values.locker_instance_type, null) != null ? { instance_type = values.locker_instance_type } : {},
    try(values.locker_backup_retention_period, null) != null ? { backup_retention_period = values.locker_backup_retention_period } : {},
    try(values.locker_db_instance_class, null) != null ? { db_instance_class = values.locker_db_instance_class } : {},
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
  source = "${get_repo_root()}/terraform/aws/catalog/units/squid-proxy"
  path   = "squid-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.squid_instance_type, null) != null ? { instance_type = values.squid_instance_type } : {},
    try(values.squid_min_size, null) != null ? { min_size = values.squid_min_size } : {},
    try(values.squid_max_size, null) != null ? { max_size = values.squid_max_size } : {},
    try(values.squid_desired_capacity, null) != null ? { desired_capacity = values.squid_desired_capacity } : {},
    try(values.squid_root_volume_size, null) != null ? { root_volume_size = values.squid_root_volume_size } : {},
    try(values.wazuh_manager_addr, null) != null ? { wazuh_manager_addr = values.wazuh_manager_addr } : {},
    try(values.wazuh_worker_addr, null) != null ? { wazuh_worker_addr = values.wazuh_worker_addr } : {},
    try(values.wazuh_group, null) != null ? { wazuh_group = values.wazuh_group } : {},
    try(values.wazuh_tag, null) != null ? { wazuh_tag = values.wazuh_tag } : {},
    try(values.sudo_user_list, null) != null ? { sudo_user_list = values.sudo_user_list } : {},
  )
}

unit "envoy-proxy" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/envoy-proxy"
  path   = "envoy-proxy"

  no_dot_terragrunt_stack = true

  values = merge(
    {
      ami_id                = values.ami_id
      virtual_hosts_domains = values.virtual_hosts_domains
    },
    try(values.envoy_instance_type, null) != null ? { instance_type = values.envoy_instance_type } : {},
    try(values.envoy_root_volume_size, null) != null ? { root_volume_size = values.envoy_root_volume_size } : {},
    try(values.envoy_min_size, null) != null ? { min_size = values.envoy_min_size } : {},
    try(values.envoy_max_size, null) != null ? { max_size = values.envoy_max_size } : {},
    try(values.envoy_desired_capacity, null) != null ? { desired_capacity = values.envoy_desired_capacity } : {},
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
  source = "${get_repo_root()}/terraform/aws/catalog/units/jump-host"
  path   = "jump-host"

  no_dot_terragrunt_stack = true

  values = merge(
    { ami_id = values.ami_id },
    try(values.jump_host_instance_type, null) != null ? { instance_type = values.jump_host_instance_type } : {},
    try(values.jump_host_root_volume_size, null) != null ? { root_volume_size = values.jump_host_root_volume_size } : {},
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

  values = merge(
    {
      cluster_version    = try(values.eks_version, null)
      admin_sso_role_arn = values.admin_role_arn
      admin_access_cidrs = values.admin_access_cidrs
      default_ami_id     = try(values.eks_ami_id, null)

      system_nodes = {
        desired_size   = try(values.system_nodes_desired_size, 1)
        min_size       = try(values.system_nodes_min_size, 1)
        max_size       = try(values.system_nodes_max_size, 50)
        instance_types = values.eks_instance_types
      }

      generic_compute = {
        desired_size   = try(values.generic_compute_desired_size, 2)
        min_size       = try(values.generic_compute_min_size, 1)
        max_size       = try(values.generic_compute_max_size, 50)
        instance_types = values.eks_instance_types
      }
    },
    try(values.monitoring, null) != null ? { monitoring = values.monitoring } : {},
    try(values.keymanager, null) != null ? { keymanager = values.keymanager } : {},
    try(values.auxillary, null) != null ? { auxillary = values.auxillary } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 5 — Kubernetes resources
# -----------------------------------------------------------------------------
unit "eks-resources" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/eks-resources"
  path   = "application-stack/eks-resources"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "utils-load-balancer" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/utils-load-balancer"
  path   = "application-stack/utils-load-balancer"

  no_dot_terragrunt_stack = true

  values = {}
}

# -----------------------------------------------------------------------------
# Phase 6 — Apps (Kubernetes workloads)
# -----------------------------------------------------------------------------
unit "alb-controller" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/alb-controller"
  path   = "application-stack/apps/alb-controller"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "external-secrets" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/external-secrets"
  path   = "application-stack/apps/external-secrets"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "istio" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/istio"
  path   = "application-stack/apps/istio"

  no_dot_terragrunt_stack = true

  values = {
    host_domains = values.istio_host_domains
  }
}

unit "otel" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/otel"
  path   = "application-stack/apps/otel"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "vector-dr" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/vector-dr"
  path   = "application-stack/apps/vector-dr"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "loki" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/loki"
  path   = "application-stack/apps/loki"

  no_dot_terragrunt_stack = true

  values = {}
}

unit "grafana" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/grafana"
  path   = "application-stack/apps/grafana"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.grafana_db_instance_class, null) != null ? { grafana_db_instance_class = values.grafana_db_instance_class } : {},
  )
}

unit "ratelimiter" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/ratelimiter"
  path   = "application-stack/apps/ratelimiter"

  no_dot_terragrunt_stack = true

  values = merge(
    {},
    try(values.ratelimiter_cache_node_type, null) != null ? { cache_node_type = values.ratelimiter_cache_node_type } : {},
  )
}

unit "hyperswitch" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/hyperswitch"
  path   = "application-stack/apps/hyperswitch"

  no_dot_terragrunt_stack = true

  values = {
    ses_email_role_arn = try(values.ses_email_role_arn, null)
  }
}

unit "decision-engine" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/decision-engine"
  path   = "application-stack/apps/decision-engine"

  no_dot_terragrunt_stack = true

  values = {
    ses_email_role_arn = try(values.ses_email_role_arn, null)
  }
}

unit "superposition" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/apps/superposition"
  path   = "application-stack/apps/superposition"

  no_dot_terragrunt_stack = true

  values = merge(
    { base_domain = values.base_domain },
    try(values.superposition_backup_retention_period, null) != null ? { backup_retention_period = values.superposition_backup_retention_period } : {},
    try(values.superposition_db_instance_class, null) != null ? { db_instance_class = values.superposition_db_instance_class } : {},
  )
}

# -----------------------------------------------------------------------------
# Phase 7 — Security rules (apply last)
# -----------------------------------------------------------------------------
unit "security-rules" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/security-rules"
  path   = "security-rules"

  no_dot_terragrunt_stack = true

  values = {
    # No vpc_id -> local.has_vpc_network = true -> reads the created vpc-network unit.
    # Every enable_* toggle is left at its catalog default (true) for full parity;
    # only the internal-only, not-yet-modeled components stay off by default:
    #   enable_encryption_service, enable_auth_proxy, enable_wazuh_endpoints
  }
}
