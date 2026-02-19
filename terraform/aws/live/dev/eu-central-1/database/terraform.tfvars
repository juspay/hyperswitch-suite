# ============================================================================
# Environment Configuration
# ============================================================================
environment  = "dev"
project_name = "hyperswitch"
region       = "eu-central-1"

# ============================================================================
# Network Configuration
# ============================================================================
# Note: VPC ID is fetched from remote state
# Subnet IDs should be updated with actual subnet IDs from VPC
subnet_ids = [
  # Replace with actual subnet IDs from VPC network module
  # Example: data.terraform_remote_state.vpc.outputs.utils_subnet_ids
]

# ============================================================================
# Global Cluster Configuration
# ============================================================================
# Enable Aurora Global Database for multi-region deployment
# Set to false to revert to single-region mode (requires cluster recreation)
create_global_cluster      = false
# global_cluster_identifier  = "hyperswitch-global-db"
# global_deletion_protection = true

# Link existing cluster as primary for global database 
use_existing_as_global_primary = false
# source_db_cluster_identifier   = "arn:aws:rds:<region>:xxxxxxxxxxxxx:cluster:hyperswitchdb-cluster"

# Enable write forwarding from secondary clusters (optional)
# Set to true to allow writes from secondary region (adds latency)
enable_global_write_forwarding = false

# ============================================================================
# RDS Cluster Configuration
# ============================================================================
cluster_identifier       = "hyperswitchdb-cluster"
engine                   = "aurora-postgresql"
engine_version           = "13.20"
engine_mode              = "provisioned"
engine_lifecycle_support = "open-source-rds-extended-support"

# Database Configuration
database_name   = null # Will use default
master_username = "postgres"
# master_password should be set via environment variable TF_VAR_master_password
# or in a separate secure variable file not committed to version control

# ============================================================================
# Multi-AZ Configuration
# ============================================================================
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
allocated_storage  = null
storage_type       = "aurora-iopt1"
iops               = null

# ============================================================================
# Network Settings
# ============================================================================
network_type             = "IPV4"
port                     = 5432
create_db_subnet_group   = true
# db_subnet_group_name     = null

# Parameter Groups
db_cluster_parameter_group_name  = "default.aurora-postgresql13"
db_instance_parameter_group_name = null

# ============================================================================
# Backup and Maintenance
# ============================================================================
backup_retention_period      = 7
preferred_backup_window      = "00:51-01:21"
preferred_maintenance_window = "thu:00:12-thu:00:42"
skip_final_snapshot          = true
final_snapshot_identifier    = null
copy_tags_to_snapshot        = false

# ============================================================================
# Security and Encryption
# ============================================================================
storage_encrypted        = true
# kms_key_id               = null
deletion_protection      = false
delete_automated_backups = true

# ============================================================================
# Monitoring
# ============================================================================
enabled_cloudwatch_logs_exports       = ["postgresql"]
performance_insights_enabled          = false
performance_insights_kms_key_id       = null
performance_insights_retention_period = 0
monitoring_interval                   = 0
database_insights_mode                = "standard"

# ============================================================================
# HTTP Endpoint
# ============================================================================
enable_http_endpoint = false

# ============================================================================
# Backtrack
# ============================================================================
backtrack_window = 0

# ============================================================================
# Security Group
# ============================================================================
create_security_group  = true
# vpc_security_group_ids = []

# ============================================================================
# Cluster Instances
# ============================================================================
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

# ============================================================================
# Tags
# ============================================================================
tags = {}
