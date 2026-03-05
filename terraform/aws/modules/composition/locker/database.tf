module "database" {
  count = var.create_locker_database ? 1 : 0

  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database?ref=database-v0.1.2"

  environment  = var.environment
  project_name = var.project_name
  region       = var.region

  vpc_id = var.vpc_id

  subnet_ids                            = var.database_config.subnet_ids
  cluster_identifier                    = var.database_config.cluster_identifier
  cluster_identifier_prefix             = var.database_config.cluster_identifier_prefix
  database_name                         = var.database_config.database_name
  engine                                = var.database_config.engine
  engine_version                        = var.database_config.engine_version
  engine_mode                           = var.database_config.engine_mode
  engine_lifecycle_support              = var.database_config.engine_lifecycle_support
  cluster_scalability_type              = var.database_config.cluster_scalability_type
  master_username                       = var.database_config.master_username
  master_password                       = var.database_config.master_password
  manage_master_user_password           = var.database_config.manage_master_user_password
  master_user_secret_kms_key_id         = var.database_config.master_user_secret_kms_key_id
  db_cluster_instance_class             = var.database_config.db_cluster_instance_class
  availability_zones                    = var.database_config.availability_zones
  allocated_storage                     = var.database_config.allocated_storage
  storage_type                          = var.database_config.storage_type
  iops                                  = var.database_config.iops
  network_type                          = var.database_config.network_type
  port                                  = var.database_config.port
  create_db_subnet_group                = var.database_config.create_db_subnet_group
  db_subnet_group_name                  = var.database_config.db_subnet_group_name
  vpc_security_group_ids                = var.database_config.vpc_security_group_ids
  db_cluster_parameter_group_name       = var.database_config.db_cluster_parameter_group_name
  db_instance_parameter_group_name      = var.database_config.db_instance_parameter_group_name
  backup_retention_period               = var.database_config.backup_retention_period
  preferred_backup_window               = var.database_config.preferred_backup_window
  preferred_maintenance_window          = var.database_config.preferred_maintenance_window
  skip_final_snapshot                   = var.database_config.skip_final_snapshot
  final_snapshot_identifier             = var.database_config.final_snapshot_identifier
  snapshot_identifier                   = var.database_config.snapshot_identifier
  copy_tags_to_snapshot                 = var.database_config.copy_tags_to_snapshot
  storage_encrypted                     = var.database_config.storage_encrypted
  kms_key_id                            = var.database_config.kms_key_id
  deletion_protection                   = var.database_config.deletion_protection
  delete_automated_backups              = var.database_config.delete_automated_backups
  iam_database_authentication_enabled   = var.database_config.iam_database_authentication_enabled
  iam_roles                             = var.database_config.iam_roles
  domain                                = var.database_config.domain
  domain_iam_role_name                  = var.database_config.domain_iam_role_name
  allow_major_version_upgrade           = var.database_config.allow_major_version_upgrade
  apply_immediately                     = var.database_config.apply_immediately
  enabled_cloudwatch_logs_exports       = var.database_config.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.database_config.performance_insights_enabled
  performance_insights_kms_key_id       = var.database_config.performance_insights_kms_key_id
  performance_insights_retention_period = var.database_config.performance_insights_retention_period
  monitoring_interval                   = var.database_config.monitoring_interval
  monitoring_role_arn                   = var.database_config.monitoring_role_arn
  database_insights_mode                = var.database_config.database_insights_mode
  enable_http_endpoint                  = var.database_config.enable_http_endpoint
  enable_local_write_forwarding         = var.database_config.enable_local_write_forwarding
  replication_source_identifier         = var.database_config.replication_source_identifier
  source_region                         = var.database_config.source_region
  backtrack_window                      = var.database_config.backtrack_window
  ca_certificate_identifier             = var.database_config.ca_certificate_identifier
  db_system_id                          = var.database_config.db_system_id
  create_security_group                 = var.database_config.create_security_group
  security_group_name                   = var.database_config.security_group_name
  security_group_description            = var.database_config.security_group_description
  scaling_configuration                 = var.database_config.scaling_configuration
  serverlessv2_scaling_configuration    = var.database_config.serverlessv2_scaling_configuration
  restore_to_point_in_time              = var.database_config.restore_to_point_in_time
  s3_import                             = var.database_config.s3_import
  create_global_cluster                 = var.database_config.create_global_cluster
  global_cluster_identifier             = var.database_config.global_cluster_identifier
  global_deletion_protection            = var.database_config.global_deletion_protection
  enable_global_write_forwarding        = var.database_config.enable_global_write_forwarding
  use_existing_as_global_primary        = var.database_config.use_existing_as_global_primary
  source_db_cluster_identifier          = var.database_config.source_db_cluster_identifier
  cluster_instances                     = var.database_config.cluster_instances

  tags = merge(local.common_tags, var.database_config.tags)
}
