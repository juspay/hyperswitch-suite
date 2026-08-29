include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# Disabled when the stack provides its own VPC via values (BYO-VPC / standalone)
dependency "vpc" {
  enabled     = try(values.vpc_id, null) == null
  config_path = "../vpc-network"

  mock_outputs = {
    eks_workers_subnet_ids = ["mock-eks_workers_subnet_ids"]
    vpc_id                 = "vpc-mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/efs?ref=efs-v0.1.1"
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  file_systems = {
    superposition-backup = {
      name             = "superposition-backup-efs"
      creation_token   = "superposition-backup-${include.root.locals.environment.full}"
      performance_mode = "generalPurpose"
      throughput_mode  = "elastic"
      encrypted        = true
      kms_key_id       = null

      # Single object in v2.x (breaking change from list in v1.x)
      lifecycle_policy = {
        transition_to_ia                    = "AFTER_30_DAYS"
        transition_to_primary_storage_class = "AFTER_1_ACCESS"
      }

      replication_overwrite_protection = "ENABLED"

      enable_backup_policy               = true
      backup_policy_status               = "ENABLED"
      file_system_policy                 = null
      bypass_policy_lockout_safety_check = false

      # Use EKS subnets for mount targets
      subnet_ids = try(values.eks_workers_subnet_ids, null) != null ? values.eks_workers_subnet_ids : dependency.vpc.outputs.eks_workers_subnet_ids

      # OPTION 2 (RECOMMENDED): Leave empty to create dedicated EFS security group
      # The module will automatically create an EFS-specific security group
      # and configure it to allow NFS (port 2049) from the EKS node security groups
      security_group_ids = []

      # VPC ID is required when creating a new security group
      vpc_id = try(values.vpc_id, null) != null ? values.vpc_id : dependency.vpc.outputs.vpc_id

      replication_configuration = null

      tags = {
        Component   = "Superposition"
        UseCase     = "Config backup and fallback"
        ManagedBy   = "Terraform"
        Environment = include.root.locals.environment.full
      }
    }
  }

  # Tags
  tags = {
    Environment = include.root.locals.environment.short
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
