locals {
  name_prefix = "${var.environment}-${var.project_name}-elasticache"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "elasticache"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )
  elasticache_replication_group_id = var.elasticache_replication_group_id != null ? var.elasticache_replication_group_id : "${local.name_prefix}-replication-group"

  elasticache_subnet_group_name = var.elasticache_subnet_group_name != null ? var.elasticache_subnet_group_name : "${local.name_prefix}-subnet-group"

  security_group_name = var.security_group_name != null ? var.security_group_name : "${local.name_prefix}-sg"
  security_group_description = var.security_group_description != null ? var.security_group_description : "Security group for ${var.project_name} ${var.environment} ElastiCache"

}
