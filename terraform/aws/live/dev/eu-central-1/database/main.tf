# ============================================================================
# RDS Aurora PostgreSQL Deployment - Dev Environment
# ============================================================================
# This configuration deploys AWS RDS Aurora PostgreSQL Cluster:
#   - Aurora PostgreSQL cluster (version 13.20)
#   - Primary instance (db.r5.large) - hyperswitchdb-mo
#   - Reader replica (db.t4g.medium) - hyperswitchdb-ro
#   - Failover replica (db.t4g.large) - failover-replica
#   - Multi-AZ deployment across eu-central-1a, eu-central-1b, eu-central-1c
#   - Automated backups with 7-day retention
#   - Performance Insights enabled
#   - Encryption at rest using KMS
#
# Access Method: Via VPC internal network only
# Security: Network isolation with security group rules
# High Availability: Multi-AZ with automatic failover
# Backups: Daily automated snapshots
# ============================================================================

provider "aws" {
  region = var.region
}

# Data sources to fetch VPC and subnet information
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hyperswitch-dev-terraform-state"
    key    = "dev/eu-central-1/vpc-network/terraform.tfstate"
    region = "eu-central-1"
  }
}

# RDS Aurora PostgreSQL Module
module "database" {
  source = "../../../../modules/composition/database"

  # Environment Configuration
  environment  = var.environment
  project_name = var.project_name

  # Network Configuration
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = var.subnet_ids

  # RDS Cluster Configuration
  cluster_identifier       = var.cluster_identifier
  engine                   = var.engine
  engine_version           = var.engine_version
  engine_mode              = var.engine_mode
  engine_lifecycle_support = var.engine_lifecycle_support

  # Database Configuration
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  # Multi-AZ Configuration
  availability_zones = var.availability_zones
  allocated_storage  = var.allocated_storage
  storage_type       = var.storage_type
  iops               = var.iops

  # Network Configuration
  network_type           = var.network_type
  port                   = var.port
  create_db_subnet_group = var.create_db_subnet_group
  db_subnet_group_name   = var.db_subnet_group_name

  # Parameter Groups
  db_cluster_parameter_group_name  = var.db_cluster_parameter_group_name
  db_instance_parameter_group_name = var.db_instance_parameter_group_name

  # Backup and Maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

  # Security and Encryption
  storage_encrypted   = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  deletion_protection = var.deletion_protection
  delete_automated_backups = var.delete_automated_backups

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  database_insights_mode                = var.database_insights_mode

  # HTTP Endpoint
  enable_http_endpoint = var.enable_http_endpoint

  # Backtrack
  backtrack_window = var.backtrack_window

  # Security Group
  create_security_group      = var.create_security_group
  vpc_security_group_ids     = var.vpc_security_group_ids
  security_group_name        = var.security_group_name
  security_group_description = var.security_group_description

  # Cluster Instances
  cluster_instances = var.cluster_instances

  # Tags
  tags = var.tags
}
