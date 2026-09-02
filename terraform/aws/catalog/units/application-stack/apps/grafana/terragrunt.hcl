# =============================================================================
# Grafana - Terragrunt Configuration
# =============================================================================
# This configuration creates IAM role for Grafana with IRSA for EKS and
# optional Aurora PostgreSQL database for persistent storage.
# =============================================================================

# -----------------------------------------------------------------------------
# Include Root Configuration
# -----------------------------------------------------------------------------
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vpc" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    database_subnet_ids = ["mock-database_subnet_ids"]
    vpc_id              = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# -----------------------------------------------------------------------------
# Terragrunt Configuration
# -----------------------------------------------------------------------------
terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/grafana?ref=apps-grafana-v0.1.3"
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------
inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  app_name     = "grafana"

  host_domains = {
    sandbox = "grafana.internal.${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"
  }

  # OIDC/IRSA Configuration
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "monitoring"
        name      = "grafana"
      }
    ]
  }

  aws_managed_policy_names = [
    "AWSXrayReadOnlyAccess",
    "CloudWatchReadOnlyAccess"
  ]

  assume_role_principals = []

  # Database Configuration
  create_database = true

  database_vpc_id                 = dependency.vpc.outputs.vpc_id
  database_subnet_ids             = dependency.vpc.outputs.database_subnet_ids
  database_create_db_subnet_group = true
  database_create_security_group  = true
  database_security_group_name    = "${include.root.locals.project_name}-grafana-db-sg"

  database_cluster_identifier = "grafana-db"

  database_engine         = "aurora-postgresql"
  database_engine_version = "16.11"

  database_name                        = "grafana"
  database_master_username             = "grafana_admin"
  database_manage_master_user_password = true

  database_cluster_instances = {
    primary = {
      instance_class               = "db.t4g.medium"
      publicly_accessible          = false
      auto_minor_version_upgrade   = true
      performance_insights_enabled = true
    }
  }

  database_backup_retention_period = 7
  database_deletion_protection     = false
  database_snapshot_identifier     = null
  database_apply_immediately       = true
  database_skip_final_snapshot     = true
  database_storage_encrypted       = true

  database_enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
