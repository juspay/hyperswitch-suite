include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/superposition?ref=apps-superposition-v0.1.7"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "hyperswitch" {
  config_path = "../hyperswitch"

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mock"
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

dependency "superposition_primary" {
  config_path = try(values.primary_superposition_config_path, try("../../../../${values.primary_region}/application-stack/apps/superposition", null))
  enabled     = try(values.is_passive, false)

  mock_outputs = {
    database_cluster_arn = "arn:aws:mock:::123456789012:mock/mock"
    db_global_cluster_id = "mock-db_global_cluster_id"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  app_name     = "superposition"

  host_domains = {
    sandbox = "superposition.internal.${include.root.locals.deployment_tier}.${include.root.locals.region_code}.${values.base_domain}"
  }

  # OIDC/IRSA Configuration
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "superposition"
        name      = "superposition-role"
      }
    ]
  }

  assume_role_principals   = []
  aws_managed_policy_names = []

  # KMS Permissions for encryption/decryption
  inline_policies = {
    kms-encrypt-decrypt = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "KMSPermissions"
          Effect   = "Allow"
          Action   = ["kms:Decrypt", "kms:Encrypt"]
          Resource = [dependency.hyperswitch.outputs.kms_key_arn]
        }
      ]
    })
  }

  # Database Configuration
  # Sandbox uses the shared/primary Superposition database; don't create a new one here.
  create_database = try(values.create_database, include.root.locals.environment.full == "sandbox" ? false : true)
  database_config = try(values.create_database, include.root.locals.environment.full == "sandbox" ? false : true) ? {
    vpc_id                   = dependency.vpc.outputs.vpc_id
    subnet_ids               = dependency.vpc.outputs.database_subnet_ids
    engine                   = "aurora-postgresql"
    engine_version           = try(values.engine_version, "17.9")
    engine_mode              = "provisioned"
    engine_lifecycle_support = "open-source-rds-extended-support"

    # Enable global cluster
    create_global_cluster          = !try(values.is_passive, false)
    global_deletion_protection     = !try(values.is_passive, false)
    use_existing_as_global_primary = !try(values.is_passive, false)

    # Read Replica Configuration
    global_cluster_identifier     = try(dependency.superposition_primary.outputs.db_global_cluster_id, null)
    replication_source_identifier = try(dependency.superposition_primary.outputs.database_cluster_arn, null)
    source_region                 = try(values.primary_region, null)

    # KMS Key Configuration - Create a new KMS key for this replica cluster
    kms = {
      create              = try(values.is_passive, false)
      multi_region        = true
      enable_key_rotation = true
    }

    master_username = try(values.is_passive, false) ? null : "postgres"
    # master_password                       = null
    availability_zones                    = ["${include.root.locals.region}a", "${include.root.locals.region}b"]
    allocated_storage                     = null
    storage_type                          = "aurora-iopt1"
    network_type                          = "IPV4"
    port                                  = 5432
    create_db_subnet_group                = true
    db_cluster_parameter_group_name       = "default.aurora-postgresql17"
    backup_retention_period               = 7
    preferred_backup_window               = "02:03-02:33"
    preferred_maintenance_window          = "tue:00:25-tue:00:55"
    skip_final_snapshot                   = true
    copy_tags_to_snapshot                 = true
    storage_encrypted                     = true
    deletion_protection                   = true
    snapshot_identifier                   = null
    kms_key_id                            = null
    apply_immediately                     = true
    delete_automated_backups              = true
    enabled_cloudwatch_logs_exports       = []
    performance_insights_enabled          = false
    performance_insights_retention_period = 0
    monitoring_interval                   = 0
    database_insights_mode                = "standard"
    enable_http_endpoint                  = false
    backtrack_window                      = 0
    create_security_group                 = true

    create_custom_parameter_group      = null
    custom_parameter_group_name        = null
    custom_parameter_group_family      = null
    custom_parameter_group_description = null
    custom_parameter_group_parameters  = null

    cluster_instances = {
      failover = {
        instance_class                        = "db.r6g.large"
        promotion_tier                        = 1
        availability_zone                     = "${include.root.locals.region}a"
        db_parameter_group_name               = "default.aurora-postgresql17"
        auto_minor_version_upgrade            = true
        publicly_accessible                   = false
        copy_tags_to_snapshot                 = false
        monitoring_interval                   = 0
        performance_insights_enabled          = false
        performance_insights_retention_period = 0
      }
    }
  } : null

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
