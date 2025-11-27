# Local values for naming and tagging
locals {
  # Naming convention following the established pattern
  name_prefix = "${var.environment}-${var.project_name}-app-storage"

  # Instance class mapping by environment
  instance_class_map = {
    dev     = "db.r6g.large"    # 2 vCPUs, 16 GB RAM - suitable for development
    integ   = "db.r6g.xlarge"   # 4 vCPUs, 32 GB RAM - suitable for integration testing
    prod    = "db.r6g.xlarge"   # 4 vCPUs, 32 GB RAM - production workload
    sandbox = "db.r6g.large"    # 2 vCPUs, 16 GB RAM - sandbox environment
    sbx     = "db.r6g.large"    # 2 vCPUs, 16 GB RAM - sandbox environment (short form)
  }

  # Select instance class based on environment or override
  instance_class = coalesce(
    var.instance_class_override,
    lookup(local.instance_class_map, var.environment, "db.r6g.large")
  )

  # Common tags applied to all resources - following established pattern
  common_tags = merge(var.tags, {
    Environment = var.environment
    Service     = "application-storage"
    ManagedBy   = "Terraform"
    Module      = "composition/application-storage"
  })

  # Environment-specific configuration flags
  is_production = contains(["prod", "production"], var.environment)
  is_sandbox    = contains(["sandbox", "sbx"], var.environment)
  is_dev        = contains(["dev", "development"], var.environment)

  # Dynamic configuration based on environment
  enhanced_monitoring_enabled = local.is_production ? true : var.monitoring_interval > 0
  performance_insights_enabled = local.is_production ? true : var.performance_insights_enabled
  deletion_protection_enabled = local.is_production ? true : var.deletion_protection

  # Backup configuration adjustments
  backup_retention_days = local.is_production ? max(var.backup_retention_period, 14) : var.backup_retention_period

  # RDS Proxy configuration
  rds_proxy_enabled = var.enable_rds_proxy

  # Environment-specific RDS Proxy defaults
  proxy_max_connections = local.is_production ? 100 : 75
  proxy_max_idle_connections = local.is_production ? 25 : 50
}