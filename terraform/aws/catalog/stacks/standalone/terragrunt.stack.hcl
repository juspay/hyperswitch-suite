# =============================================================================
# Standalone (self-host) Hyperswitch stack
# =============================================================================
# Minimal single-region composition for self-hosting merchants:
#
#   Phase 1 — Data layer:      database, elasticache, efs
#   Phase 2 — Compute:         application-stack/eks-01
#   Phase 3 — K8s resources:   application-stack/eks-resources
#   Phase 4 — Security rules:  security-rules (apply last)
#
# The VPC is merchant-provided (BYO-VPC): vpc_id, vpc_cidr and the subnet id
# lists come from the stack values rendered into the live terragrunt.stack.hcl
# by scripts/self-host/generate.sh. Unit `path`s match the internal stacks so
# terraform state keys line up with the ArgoCD $tfstate parameter paths.
# =============================================================================

# -----------------------------------------------------------------------------
# Phase 1 — Data layer
# -----------------------------------------------------------------------------
unit "database" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/database"
  path   = "database"

  no_dot_terragrunt_stack = true

  values = {
    vpc_id              = values.vpc_id
    database_subnet_ids = values.database_subnet_ids
    db_instance_class   = values.db_instance_class
    engine_version      = values.db_engine_version
  }
}

unit "elasticache" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/elasticache"
  path   = "elasticache"

  no_dot_terragrunt_stack = true

  values = {
    vpc_id                 = values.vpc_id
    elasticache_subnet_ids = values.elasticache_subnet_ids
    cache_node_type        = values.cache_node_type
  }
}

unit "efs" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/efs"
  path   = "efs"

  no_dot_terragrunt_stack = true

  values = {
    vpc_id                 = values.vpc_id
    eks_workers_subnet_ids = values.eks_workers_subnet_ids
  }
}

# -----------------------------------------------------------------------------
# Phase 2 — Compute
# -----------------------------------------------------------------------------
unit "eks-01" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/eks-01"
  path   = "application-stack/eks-01"

  no_dot_terragrunt_stack = true

  values = {
    vpc_id                       = values.vpc_id
    eks_control_plane_subnet_ids = values.eks_control_plane_subnet_ids
    eks_workers_subnet_ids       = values.eks_workers_subnet_ids

    cluster_version    = values.eks_version
    admin_sso_role_arn = values.admin_role_arn
    admin_access_cidrs = values.admin_access_cidrs
    default_ami_id     = try(values.eks_ami_id, null)

    # Allow in-cluster tooling (ArgoCD tfstate plugin) to read terraform state
    state_bucket             = values.state_bucket
    state_bucket_read_access = true

    system_nodes = {
      desired_size   = try(values.system_nodes_desired_size, 1)
      instance_types = values.eks_instance_types
    }

    generic_compute = {
      desired_size   = try(values.generic_compute_desired_size, 2)
      min_size       = 1
      instance_types = values.eks_instance_types
    }
  }
}

# -----------------------------------------------------------------------------
# Phase 3 — Kubernetes resources (apply after eks-01)
# -----------------------------------------------------------------------------
unit "eks-resources" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/application-stack/eks-resources"
  path   = "application-stack/eks-resources"

  no_dot_terragrunt_stack = true

  values = {
    create_ecr_registry_secret = false
  }
}

# -----------------------------------------------------------------------------
# Phase 4 — Security rules (apply last)
# -----------------------------------------------------------------------------
unit "security-rules" {
  source = "${get_repo_root()}/terraform/aws/catalog/units/security-rules"
  path   = "security-rules"

  no_dot_terragrunt_stack = true

  values = {
    vpc_id   = values.vpc_id
    vpc_cidr = values.vpc_cidr

    # Only the components present in this stack
    enable_efs                 = true
    enable_squid_proxy         = false
    enable_jump_host           = false
    enable_locker              = false
    enable_istio               = false
    enable_envoy_proxy         = false
    enable_kafka               = false
    enable_grafana             = false
    enable_utils_load_balancer = false
    enable_loki                = false
    enable_ratelimiter         = false

    # Nodes need general outbound access (image pulls, AWS APIs, webhooks)
    enable_open_node_egress = true
  }
}
