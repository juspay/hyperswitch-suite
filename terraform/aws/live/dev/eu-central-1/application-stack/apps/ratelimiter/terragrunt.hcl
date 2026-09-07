include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    elasticache_subnet_ids = ["mock-elasticache_subnet_ids"]
    vpc_id                 = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/ratelimiter?ref=ratelimiter-v0.1.0"
}

inputs = {

  environment  = include.root.locals.environment.short
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  vpc_id = dependency.vpc.outputs.vpc_id

  # =========================================================================
  # EKS OIDC Configuration (for IRSA)
  # =========================================================================
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "ratelimiter"
        name      = "ratelimiter-sa"
      }
    ]
  }

  # AWS Managed Policy Attachments
  aws_managed_policy_names = []

  # Customer Managed Policy Attachments
  customer_managed_policy_arns = []

  # Inline Policies (map of policy name to policy JSON)
  inline_policies = {}

  # Additional Assume Role Principals
  assume_role_principals = []

  # Additional Assume Role Statements
  additional_assume_role_statements = []

  # =========================================================================
  # ElastiCache Configuration
  # =========================================================================
  elasticache_config = {
    enabled                          = true
    elasticache_replication_group_id = "${include.root.locals.environment.short}-${include.root.locals.project_name}-ratelimiter"
    subnet_ids                       = dependency.vpc.outputs.elasticache_subnet_ids
    engine                           = "valkey"
    engine_version                   = "8.2"
    parameter_group_name             = "default.valkey8"
    port                             = 6379
    node_type                        = "cache.t3.small"
    num_cache_clusters               = 2
    num_node_groups                  = null
    replicas_per_node_group          = null
    cluster_mode                     = "disabled"
    automatic_failover_enabled       = true
    multi_az_enabled                 = false
    at_rest_encryption_enabled       = true
    transit_encryption_enabled       = false
    auth_token                       = null
    create_subnet_group              = true
    subnet_group_name                = null
    create_security_group            = true
    existing_security_group_ids      = []
    maintenance_window               = "sun:05:00-sun:06:00"
    snapshot_window                  = "03:00-05:00"
    snapshot_retention_limit         = 1
    apply_immediately                = false
  }

  # =========================================================================
  # Load Balancer Security Group Configuration
  # =========================================================================
  create_lb_security_group = true
  # lb_security_group_name   = null
  # lb_security_group_description = "Security group for rate limiter load balancer"

  # Ingress rules for LB security group
  lb_ingress_rules = {}

  # Egress rules for LB security group
  lb_egress_rules = {}

  # Tags
  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
    Component   = "ratelimiter"
  }

}
