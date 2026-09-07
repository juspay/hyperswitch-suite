include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database?ref=database-v0.1.6"
}

# Disabled when the stack provides its own VPC via values (BYO-VPC / standalone)
dependency "vpc" {
  enabled     = try(values.vpc_id, null) == null
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id              = "vpc-12345678"
    database_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "primary_database" {
  config_path = try(values.primary_database_config_path, try("../../${values.primary_region}/database", null))

  enabled = try(values.is_passive, false)

  mock_outputs = {
    cluster_arn = "hyperswitchdb-cluster-arn"
  }

  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  region       = include.root.locals.region

  vpc_id     = try(values.vpc_id, null) != null ? values.vpc_id : dependency.vpc.outputs.vpc_id
  subnet_ids = try(values.database_subnet_ids, null) != null ? values.database_subnet_ids : dependency.vpc.outputs.database_subnet_ids

  cluster_identifier       = try(values.cluster_identifier, null)
  engine                   = "aurora-postgresql"
  engine_version           = try(values.engine_version, "17.9")
  engine_mode              = "provisioned"
  engine_lifecycle_support = "open-source-rds-extended-support"
  # allow_major_version_upgrade = true
  apply_immediately = true

  # Enable global cluster
  create_global_cluster          = !try(values.is_passive, false)
  global_deletion_protection     = !try(values.is_passive, false)
  use_existing_as_global_primary = !try(values.is_passive, false)

  # Read Replica Configuration - replicates from ap-south-1
  global_cluster_identifier     = try(dependency.primary_database.outputs.global_cluster_id, null)
  replication_source_identifier = try(dependency.primary_database.outputs.cluster_arn, null)
  source_region                 = try(values.primary_region, null)

  # KMS Key Configuration - Create a new KMS key for this replica cluster
  kms = {
    create              = try(values.is_passive, false)
    multi_region        = true
    enable_key_rotation = true
  }

  availability_zones = ["${include.root.locals.region}a", "${include.root.locals.region}b"]
  allocated_storage  = null
  storage_type       = "aurora-iopt1"
  iops               = null

  network_type           = "IPV4"
  port                   = 5432
  create_db_subnet_group = true

  db_cluster_parameter_group_name  = "default.aurora-postgresql17"
  db_instance_parameter_group_name = null

  # Custom Parameter Group Configuration - Disable SSL
  create_custom_parameter_group = true
  custom_parameter_group_family = "aurora-postgresql17"
  custom_parameter_group_parameters = [
    {
      name         = "rds.force_ssl"
      value        = "0"
      apply_method = "immediate"
    }
  ]

  backup_retention_period      = 7
  preferred_backup_window      = "00:51-01:21"
  preferred_maintenance_window = "thu:00:12-thu:00:42"
  skip_final_snapshot          = true
  final_snapshot_identifier    = null
  copy_tags_to_snapshot        = false

  storage_encrypted        = true
  deletion_protection      = true
  delete_automated_backups = true

  enabled_cloudwatch_logs_exports       = ["postgresql"]
  performance_insights_enabled          = false
  performance_insights_kms_key_id       = null
  performance_insights_retention_period = 0
  monitoring_interval                   = 0
  database_insights_mode                = "standard"

  enable_http_endpoint = false

  backtrack_window = 0

  create_security_group = true

  cluster_instances = {
    primary = {
      identifier                            = try(values.cluster_instance_identifier, null)
      instance_class                        = try(values.db_instance_class, "db.r5.large")
      promotion_tier                        = 0
      availability_zone                     = "${include.root.locals.region}a"
      db_parameter_group_name               = "default.aurora-postgresql17"
      performance_insights_enabled          = true
      performance_insights_retention_period = 7
      auto_minor_version_upgrade            = true
      publicly_accessible                   = false
      copy_tags_to_snapshot                 = false
      monitoring_interval                   = 0
      tags = {
        managed_by = "hyperswitch"
      }
    }
    # failover = {
    #   identifier                   = "failover-replica-1"
    #   instance_class               = "db.r5.xlarge"
    #   promotion_tier               = 1
    #   availability_zone            = "${include.root.locals.region}b"
    #   db_parameter_group_name      = "default.aurora-postgresql17"
    #   performance_insights_enabled = true
    #   performance_insights_retention_period = 7
    #   auto_minor_version_upgrade = true
    #   publicly_accessible        = false
    #   copy_tags_to_snapshot      = false
    #   monitoring_interval        = 0
    #   tags                       = {}
    # }
  }

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
