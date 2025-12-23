# RDS Aurora PostgreSQL Application Storage
# This composition module creates an Aurora PostgreSQL cluster with 1 replica
# Uses Terraform registry modules for underlying AWS resources

# Security Group for Aurora Database
resource "aws_security_group" "aurora_db" {
  name_prefix = "${local.name_prefix}-aurora-db-"
  vpc_id      = var.vpc_id
  description = "Security group for Aurora PostgreSQL database"

  # Inbound rule: Allow application security group to access PostgreSQL port
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.application_security_group_id]
    description     = "PostgreSQL access from application security group"
  }

  # No outbound rules as specified in requirements

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-db-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DB Subnet Group (using existing subnets)
resource "aws_db_subnet_group" "aurora" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet-group"
  })
}

# Random password for master user (will be stored in Secrets Manager)
resource "random_password" "master_password" {
  length  = 16
  special = true
}

# Aurora PostgreSQL Cluster using Terraform Registry Module
module "aurora_postgresql" {
  source = "terraform-aws-modules/rds-aurora/aws"

  name               = local.name_prefix
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version
  storage_encrypted  = true
  kms_key_id         = var.kms_key_id

  vpc_id                = var.vpc_id
  db_subnet_group_name  = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora_db.id]

  # Master credentials
  master_username = var.master_username
  master_password = random_password.master_password.result

  # Secrets Manager integration
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_id

  # Instance configuration
  instances = {
    primary = {
      instance_class      = local.instance_class
      publicly_accessible = false
    }
    replica = {
      identifier         = "${local.name_prefix}-replica"
      instance_class     = local.instance_class
      publicly_accessible = false
    }
  }

  # Backup configuration - Daily snapshots
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.backup_window
  preferred_maintenance_window = var.maintenance_window

  # Enable daily automated snapshots
  copy_tags_to_snapshot = true

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval            = var.monitoring_interval
  monitoring_role_arn           = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id      = var.performance_insights_enabled ? var.kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Parameter groups
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgresql.name
  db_parameter_group_name        = aws_db_parameter_group.postgresql.name

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = local.common_tags
}

# Enhanced Monitoring IAM Role (conditionally created)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${local.name_prefix}-aurora-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Cluster Parameter Group for PostgreSQL optimization
resource "aws_rds_cluster_parameter_group" "postgresql" {
  family      = var.parameter_group_family
  name        = "${local.name_prefix}-aurora-cluster-pg"
  description = "Aurora PostgreSQL cluster parameter group for ${local.name_prefix}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-cluster-pg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DB Parameter Group for PostgreSQL optimization
resource "aws_db_parameter_group" "postgresql" {
  family      = var.parameter_group_family
  name        = "${local.name_prefix}-aurora-db-pg"
  description = "Aurora PostgreSQL DB parameter group for ${local.name_prefix}"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aurora-db-pg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# RDS PROXY (OPTIONAL)
# =============================================================================

# Security Group for RDS Proxy (conditionally created)
resource "aws_security_group" "rds_proxy" {
  count       = var.enable_rds_proxy ? 1 : 0
  name_prefix = "${local.name_prefix}-rds-proxy-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS Proxy"

  # Inbound rule: Allow application security group to access PostgreSQL port through proxy
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.application_security_group_id]
    description     = "PostgreSQL access from application security group via RDS Proxy"
  }

  # Outbound rule: Allow proxy to connect to Aurora cluster
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.aurora_db.id]
    description     = "PostgreSQL access to Aurora cluster"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-proxy-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Update Aurora security group to allow RDS Proxy access
resource "aws_security_group_rule" "aurora_from_proxy" {
  count                    = var.enable_rds_proxy ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds_proxy[0].id
  security_group_id        = aws_security_group.aurora_db.id
  description              = "PostgreSQL access from RDS Proxy"
}

# IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0
  name  = "${local.name_prefix}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for RDS Proxy to access Secrets Manager
resource "aws_iam_role_policy" "rds_proxy_secrets" {
  count = var.enable_rds_proxy ? 1 : 0
  name  = "${local.name_prefix}-rds-proxy-secrets-policy"
  role  = aws_iam_role.rds_proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          module.aurora_postgresql.cluster_master_user_secret[0].secret_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          var.kms_key_id != null ? var.kms_key_id : data.aws_kms_key.rds_default[0].arn
        ]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# RDS Proxy
resource "aws_db_proxy" "aurora_proxy" {
  count                  = var.enable_rds_proxy ? 1 : 0
  name                   = "${local.name_prefix}-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = module.aurora_postgresql.cluster_master_user_secret[0].secret_arn
  }
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids         = var.rds_proxy_subnet_ids != null ? var.rds_proxy_subnet_ids : var.database_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_proxy[0].id]

  # Connection settings
  idle_client_timeout    = var.rds_proxy_idle_client_timeout
  max_connections_percent = var.rds_proxy_max_connections_percent
  max_idle_connections_percent = var.rds_proxy_max_idle_connections_percent
  require_tls            = var.rds_proxy_require_tls

  # Debug logging
  debug_logging = var.rds_proxy_debug_logging

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-proxy"
  })

  depends_on = [
    aws_iam_role_policy.rds_proxy_secrets
  ]
}

# RDS Proxy Target Group
resource "aws_db_proxy_default_target_group" "aurora_proxy" {
  count         = var.enable_rds_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.aurora_proxy[0].name

  connection_pool_config {
    max_connections_percent      = var.rds_proxy_max_connections_percent
    max_idle_connections_percent = var.rds_proxy_max_idle_connections_percent
    connection_borrow_timeout    = var.rds_proxy_connection_borrow_timeout
    session_pinning_filters      = var.rds_proxy_session_pinning_filters
  }
}

# RDS Proxy Targets (Aurora Cluster)
resource "aws_db_proxy_target" "aurora_cluster" {
  count                 = var.enable_rds_proxy ? 1 : 0
  db_cluster_identifier = module.aurora_postgresql.cluster_id
  db_proxy_name         = aws_db_proxy.aurora_proxy[0].name
  target_group_name     = aws_db_proxy_default_target_group.aurora_proxy[0].name
}