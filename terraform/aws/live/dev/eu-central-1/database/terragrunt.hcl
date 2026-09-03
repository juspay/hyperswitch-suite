include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/database"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    vpc_id              = "vpc-XXXXXXXXXXXXXXXXX"
    database_subnet_ids = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-YYYYYYYYYYYYYYYYY", "subnet-ZZZZZZZZZZZZZZZZZ"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.database_subnet_ids

  create_global_cluster          = false
  global_cluster_identifier      = "hyperswitch-global-db"
  global_deletion_protection     = true
  enable_global_write_forwarding = false
  use_existing_as_global_primary = false
  source_db_cluster_identifier   = null

  cluster_identifier       = "hyperswitchdb-cluster"
  engine                   = "aurora-postgresql"
  engine_version           = "13.20"
  engine_mode              = "provisioned"
  engine_lifecycle_support = "open-source-rds-extended-support"

  database_name   = null
  master_username = "postgres"
  master_password = null

  availability_zones = include.root.locals.availability_zones
  allocated_storage  = null
  storage_type       = "aurora-iopt1"
  iops               = null

  network_type           = "IPV4"
  port                   = 5432
  create_db_subnet_group = true
  db_subnet_group_name   = null

  db_cluster_parameter_group_name  = "default.aurora-postgresql13"
  db_instance_parameter_group_name = null

  create_custom_parameter_group = false

  backup_retention_period      = 7
  preferred_backup_window      = "00:51-01:21"
  preferred_maintenance_window = "thu:00:12-thu:00:42"
  skip_final_snapshot          = true
  final_snapshot_identifier    = null
  copy_tags_to_snapshot        = false

  storage_encrypted        = true
  kms_key_id               = null
  deletion_protection      = false
  delete_automated_backups = true

  enabled_cloudwatch_logs_exports       = ["postgresql"]
  performance_insights_enabled          = false
  performance_insights_kms_key_id       = null
  performance_insights_retention_period = 0
  monitoring_interval                   = 0
  database_insights_mode                = "standard"

  enable_http_endpoint = false
  backtrack_window     = 0

  create_security_group  = true
  vpc_security_group_ids = []

  cluster_instances = {
    mo = {
      identifier                            = "hyperswitchdb-mo"
      instance_class                        = "db.r5.large"
      promotion_tier                        = 0
      availability_zone                     = "eu-central-1a"
      db_parameter_group_name               = "default.aurora-postgresql13"
      performance_insights_enabled          = true
      performance_insights_kms_key_id       = null
      performance_insights_retention_period = 7
      ca_cert_identifier                    = null
      auto_minor_version_upgrade            = true
      publicly_accessible                   = false
      copy_tags_to_snapshot                 = false
      monitoring_interval                   = 0
      tags                                  = {}
    }
    ro = {
      identifier                            = "hyperswitchdb-ro"
      instance_class                        = "db.r5.large"
      promotion_tier                        = 1
      availability_zone                     = "eu-central-1c"
      db_parameter_group_name               = "default.aurora-postgresql13"
      performance_insights_enabled          = true
      performance_insights_kms_key_id       = null
      performance_insights_retention_period = 7
      ca_cert_identifier                    = null
      auto_minor_version_upgrade            = true
      publicly_accessible                   = false
      copy_tags_to_snapshot                 = false
      monitoring_interval                   = 0
      tags                                  = {}
    }
    failover = {
      identifier                            = "failover-replica"
      instance_class                        = "db.r5.large"
      promotion_tier                        = 1
      availability_zone                     = "eu-central-1b"
      db_parameter_group_name               = "default.aurora-postgresql13"
      performance_insights_enabled          = true
      performance_insights_kms_key_id       = null
      performance_insights_retention_period = 7
      ca_cert_identifier                    = null
      auto_minor_version_upgrade            = true
      publicly_accessible                   = false
      copy_tags_to_snapshot                 = false
      monitoring_interval                   = 0
      tags                                  = {}
    }
  }

  tags = include.root.locals.tags
}
