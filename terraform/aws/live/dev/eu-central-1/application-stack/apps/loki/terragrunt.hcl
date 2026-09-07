# =============================================================================
# Loki - Terragrunt Configuration
# =============================================================================
# This configuration creates IAM role for Loki with optional S3 bucket for
# log storage. Uses IRSA (IAM Roles for Service Accounts) for EKS.
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
    cluster_name           = "mock-cluster"
    node_security_group_id = "sg-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vpc_network" {
  config_path = "../../../vpc-network"

  mock_outputs = {
    vpc_cidr_block = "mock-vpc_cidr_block"
    vpc_id         = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# -----------------------------------------------------------------------------
# Terragrunt Configuration
# -----------------------------------------------------------------------------
terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/loki?ref=tf/app/loki-v0.1.3"
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------
inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  app_name     = "loki"
  role_name    = null

  # OIDC/IRSA Configuration
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "loki"
        name      = "loki"
      }
    ]
  }

  # S3 Bucket Configuration for Loki Logs
  s3 = {
    create             = true
    bucket_name        = null
    force_destroy      = false
    versioning_enabled = false
    lifecycle_rules = [
      {
        id      = "expire-loki-logs-after-1-year"
        enabled = true
        expiration = {
          days = 365
        }
      }
    ]
  }

  # Security Group Configuration for ALB Ingress
  vpc_id                     = dependency.vpc_network.outputs.vpc_id
  create_security_group      = true
  security_group_name        = null
  security_group_description = "Security group for Loki ALB ingress"

  # Ingress rules - allow HTTP from internal VPC CIDR
  security_group_ingress_rules = [
    {
      description = "HTTP from internal VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [dependency.vpc_network.outputs.vpc_cidr_block]
    }
  ]

  # EKS node security group ID - module will create both egress from LB and ingress to EKS
  eks_node_security_group_id = dependency.eks.outputs.node_security_group_id

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terragrunt"
    Region      = include.root.locals.region
  }
}
