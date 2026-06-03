locals {
  name_prefix = "${var.environment}-${var.project_name}-rds"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "Database"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  region                     = var.region != null ? var.region : data.aws_region.current.region
  cluster_identifier         = var.cluster_identifier != null ? var.cluster_identifier : "${local.name_prefix}-cluster"
  db_subnet_group_name       = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${local.name_prefix}-subnet-group"
  security_group_name        = var.security_group_name != null ? var.security_group_name : "${local.name_prefix}-sg"
  security_group_description = var.security_group_description != null ? var.security_group_description : "Security group for ${var.project_name} ${var.environment} RDS"

  # Global Cluster Configuration
  global_cluster_identifier = var.global_cluster_identifier != null ? var.global_cluster_identifier : "${local.name_prefix}-global"
  is_secondary_cluster      = var.replication_source_identifier != null

  # KMS Configuration
  # Create KMS key if requested via kms.create = true
  kms_create = var.kms != null ? var.kms.create : false

  # Determine which KMS key ARN to use for RDS encryption
  # Priority: 1. var.kms_key_id (legacy/explicit), 2. Created KMS key, 3. null (AWS managed)
  kms_key_arn_for_storage = var.kms_key_id != null ? var.kms_key_id : (
    local.kms_create ? module.kms[0].key_arn : null
  )

  # Determine which KMS key to use for master user secret encryption
  # Priority: 1. var.master_user_secret_kms_key_id (explicit), 2. Created KMS key, 3. null (AWS managed)
  kms_key_arn_for_master_secret = var.master_user_secret_kms_key_id != null ? var.master_user_secret_kms_key_id : (
    local.kms_create ? module.kms[0].key_arn : null
  )

  # Determine which KMS key to use for Performance Insights
  # Priority: 1. var.performance_insights_kms_key_id (explicit), 2. Created KMS key, 3. null (AWS managed)
  kms_key_arn_for_performance_insights = var.performance_insights_kms_key_id != null ? var.performance_insights_kms_key_id : (
    local.kms_create ? module.kms[0].key_arn : null
  )
}
