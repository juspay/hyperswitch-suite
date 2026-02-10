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
}
