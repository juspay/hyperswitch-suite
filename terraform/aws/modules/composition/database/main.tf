data "aws_region" "current" {}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = local.db_subnet_group_name
  subnet_ids  = var.subnet_ids
  description = "${title(var.project_name)} ${title(var.environment)} RDS subnet group"

  tags = merge(local.common_tags, {
    Name = local.db_subnet_group_name
  })
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  count = var.create_security_group ? 1 : 0

  name                   = local.security_group_name
  description            = local.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}

# RDS Cluster
resource "aws_rds_cluster" "main" {
  # Core Configuration
  cluster_identifier        = local.cluster_identifier
  cluster_identifier_prefix = var.cluster_identifier_prefix
  engine                    = var.engine
  engine_version            = var.engine_version
  engine_mode               = var.engine_mode
  engine_lifecycle_support  = var.engine_lifecycle_support

  # Database Configuration
  database_name                 = var.database_name
  master_username               = var.master_username
  master_password               = var.master_password
  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  # Multi-AZ Cluster Configuration
  db_cluster_instance_class = var.db_cluster_instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = var.storage_type
  iops                      = var.iops

  # Cluster Scalability
  cluster_scalability_type = var.cluster_scalability_type

  # Network Configuration
  availability_zones     = var.availability_zones
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.main[0].name : var.db_subnet_group_name
  vpc_security_group_ids = concat(var.vpc_security_group_ids, var.create_security_group ? [aws_security_group.rds_sg[0].id] : [])
  network_type           = var.network_type
  port                   = var.port

  # Parameter Groups
  db_cluster_parameter_group_name  = var.db_cluster_parameter_group_name
  db_instance_parameter_group_name = var.db_instance_parameter_group_name

  # Backup and Maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  snapshot_identifier          = var.snapshot_identifier
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

  # Security and Encryption
  storage_encrypted                   = var.storage_encrypted
  kms_key_id                          = var.kms_key_id
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  iam_roles                           = var.iam_roles

  # Domain Join
  domain               = var.domain
  domain_iam_role_name = var.domain_iam_role_name

  # Deletion Protection
  deletion_protection     = var.deletion_protection
  delete_automated_backups = var.delete_automated_backups

  # Version Management
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_role_arn
  database_insights_mode                = var.database_insights_mode

  # Serverless v1 Scaling Configuration
  dynamic "scaling_configuration" {
    for_each = var.scaling_configuration != null ? [var.scaling_configuration] : []
    content {
      auto_pause               = scaling_configuration.value.auto_pause
      max_capacity             = scaling_configuration.value.max_capacity
      min_capacity             = scaling_configuration.value.min_capacity
      seconds_before_timeout   = scaling_configuration.value.seconds_before_timeout
      seconds_until_auto_pause = scaling_configuration.value.seconds_until_auto_pause
      timeout_action           = scaling_configuration.value.timeout_action
    }
  }

  # Serverless v2 Scaling Configuration
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration != null ? [var.serverlessv2_scaling_configuration] : []
    content {
      max_capacity             = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity             = serverlessv2_scaling_configuration.value.min_capacity
      seconds_until_auto_pause = serverlessv2_scaling_configuration.value.seconds_until_auto_pause
    }
  }

  # Global Cluster
  global_cluster_identifier      = var.global_cluster_identifier
  enable_global_write_forwarding = var.enable_global_write_forwarding

  # Local Write Forwarding
  enable_local_write_forwarding = var.enable_local_write_forwarding

  # HTTP Endpoint
  enable_http_endpoint = var.enable_http_endpoint

  # Replication
  replication_source_identifier = var.replication_source_identifier
  source_region                 = var.source_region

  # Point-in-Time Restore
  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []
    content {
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifier
      source_cluster_resource_id = restore_to_point_in_time.value.source_cluster_resource_id
      restore_type               = restore_to_point_in_time.value.restore_type
      use_latest_restorable_time = restore_to_point_in_time.value.use_latest_restorable_time
      restore_to_time            = restore_to_point_in_time.value.restore_to_time
    }
  }

  # S3 Import
  dynamic "s3_import" {
    for_each = var.s3_import != null ? [var.s3_import] : []
    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = s3_import.value.bucket_prefix
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = s3_import.value.source_engine
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  # Backtrack
  backtrack_window = var.backtrack_window

  # CA Certificate
  ca_certificate_identifier = var.ca_certificate_identifier

  # Custom DB System
  db_system_id = var.db_system_id

  # Region
  region = local.region

  # Tags
  tags = merge(local.common_tags, {
    Name = local.cluster_identifier
  })

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      master_password,
    ]
  }
}

# RDS Cluster Instances
resource "aws_rds_cluster_instance" "instances" {
  for_each = var.cluster_instances

  # Identifiers
  identifier        = each.value.identifier != null ? each.value.identifier : "${local.cluster_identifier}-${each.key}"
  identifier_prefix = each.value.identifier_prefix
  cluster_identifier = aws_rds_cluster.main.id

  # Instance Configuration
  instance_class = each.value.instance_class
  engine         = coalesce(each.value.engine, var.engine)
  engine_version = coalesce(each.value.engine_version, var.engine_version)

  # Network Configuration
  publicly_accessible  = each.value.publicly_accessible
  availability_zone    = each.value.availability_zone
  db_subnet_group_name = var.create_db_subnet_group ? aws_db_subnet_group.main[0].name : var.db_subnet_group_name

  # Parameter Group
  db_parameter_group_name = each.value.db_parameter_group_name

  # Maintenance and Updates
  apply_immediately          = each.value.apply_immediately
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  preferred_backup_window    = each.value.preferred_backup_window
  preferred_maintenance_window = each.value.preferred_maintenance_window

  # Monitoring
  monitoring_role_arn = each.value.monitoring_role_arn != null ? each.value.monitoring_role_arn : var.monitoring_role_arn
  monitoring_interval = each.value.monitoring_interval

  # Performance Insights
  performance_insights_enabled          = each.value.performance_insights_enabled != null ? each.value.performance_insights_enabled : var.performance_insights_enabled
  performance_insights_kms_key_id       = each.value.performance_insights_kms_key_id != null ? each.value.performance_insights_kms_key_id : var.performance_insights_kms_key_id
  performance_insights_retention_period = each.value.performance_insights_retention_period

  # High Availability
  promotion_tier = each.value.promotion_tier

  # Backup
  copy_tags_to_snapshot = each.value.copy_tags_to_snapshot

  # Security
  ca_cert_identifier = each.value.ca_cert_identifier

  # Custom IAM Profile
  custom_iam_instance_profile = each.value.custom_iam_instance_profile

  # Deletion
  force_destroy = each.value.force_destroy

  # Tags
  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name = each.value.identifier != null ? each.value.identifier : "${local.cluster_identifier}-${each.key}"
    }
  )
}
