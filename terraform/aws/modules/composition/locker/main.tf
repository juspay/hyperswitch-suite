provider "aws" {
  region = var.region
}

# =========================================================================
# DATA SOURCES
# =========================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# =========================================================================
# NETWORK RESOURCES
# =========================================================================
resource "aws_subnet" "locker" {
  count             = var.create_subnet ? 1 : 0
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.subnet_availability_zone != null ? var.subnet_availability_zone : data.aws_availability_zones.available.names[0]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-subnet"
    }
  )
}

# =========================================================================
# SECURITY - SSH KEY PAIR
# =========================================================================
# Auto-generate SSH key pair if public_key not provided
resource "tls_private_key" "locker" {
  count     = var.create_key_pair && var.public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (from provided or generated public key)
resource "aws_key_pair" "locker" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = var.public_key != null ? var.public_key : tls_private_key.locker[0].public_key_openssh

  tags = local.common_tags
}

# Store auto-generated private key in SSM Parameter Store
resource "aws_ssm_parameter" "locker_private_key" {
  count       = var.create_key_pair && var.public_key == null ? 1 : 0
  name        = "/${var.environment}/${var.project_name}/locker/ssh-private-key"
  description = "Auto-generated SSH private key for locker instance"
  type        = "SecureString"
  value       = tls_private_key.locker[0].private_key_pem

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-key"
    }
  )
}

# =========================================================================
# SECURITY - LOCKER SECURITY GROUP
# =========================================================================
resource "aws_security_group" "locker" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for locker instance"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# =========================================================================
# LOCKER SECURITY GROUP - INGRESS RULES
# =========================================================================
# Internal rule: Allow traffic from NLB (required for module functionality)
resource "aws_security_group_rule" "locker_ingress_from_nlb" {
  security_group_id        = local.locker_security_group_id
  type                     = "ingress"
  from_port                = var.locker_port
  to_port                  = var.locker_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  description              = "Allow traffic from NLB to locker instance"
}

# =========================================================================
# SECURITY - NLB SECURITY GROUP
# =========================================================================
resource "aws_security_group" "nlb" {
  name        = "${local.name_prefix}-nlb-sg"
  description = "Security group for locker Network Load Balancer"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# =========================================================================
# NLB SECURITY GROUP - EGRESS RULES
# =========================================================================
# Internal rule: Allow NLB to send traffic to locker instance (required for module functionality)
resource "aws_security_group_rule" "nlb_egress_to_locker" {
  security_group_id        = aws_security_group.nlb.id
  type                     = "egress"
  from_port                = var.locker_port
  to_port                  = var.locker_port
  protocol                 = "tcp"
  source_security_group_id = local.locker_security_group_id
  description              = "Allow NLB to send traffic to locker instance"
}

# =========================================================================
# MONITORING - CLOUDWATCH LOGS
# =========================================================================
resource "aws_cloudwatch_log_group" "locker" {
  name              = "/aws/ec2/locker/${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )
}

# =========================================================================
# IAM - ROLE & INSTANCE PROFILE
# =========================================================================
resource "aws_iam_role" "locker" {
  name        = "${local.name_prefix}-role"
  description = "IAM role for locker card vault instance"
  path        = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "locker" {
  name = "${local.name_prefix}-profile"
  role = aws_iam_role.locker.name

  tags = local.common_tags
}

# =========================================================================
# IAM - CUSTOM POLICIES
# =========================================================================
# CloudWatch Logs Policy
resource "aws_iam_policy" "locker_logs" {
  name = "${local.name_prefix}-logs-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [aws_cloudwatch_log_group.locker.arn]
      }
    ]
  })

  tags = local.common_tags
}

# ECR Policy
resource "aws_iam_policy" "locker_ecr" {
  name = "${local.name_prefix}-ecr-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "0"
        Effect   = "Allow"
        Action   = "ecr:*"
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# KMS Policy
resource "aws_iam_policy" "locker_kms" {
  name = "${local.name_prefix}-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "0"
        Effect = "Allow"
        Action = [
          "kms:ListKeys",
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ListAliases",
          "kms:GenerateDataKey",
          "kms:CreateAlias",
          "kms:DescribeKey",
          "kms:CreateKey",
          "kms:CreateCustomKeyStore"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - POLICY ATTACHMENTS
# =========================================================================
# Custom Policy Attachments
resource "aws_iam_role_policy_attachment" "locker_logs" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker_logs.arn
}

resource "aws_iam_role_policy_attachment" "locker_ecr" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker_ecr.arn
}

resource "aws_iam_role_policy_attachment" "locker_kms" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker_kms.arn
}

# AWS Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.locker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_fullaccess" {
  role       = aws_iam_role.locker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.locker.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =========================================================================
# COMPUTE - EC2 INSTANCES
# =========================================================================
module "locker_instance" {
  count = var.instance_count

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.5"

  name = "${local.name_prefix}-instance-${count.index}"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_name
  monitoring                  = true
  subnet_id                   = local.locker_subnet_id
  vpc_security_group_ids      = [local.locker_security_group_id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.locker.name
  create_security_group       = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-${count.index}"
  })
}

# =========================================================================
# LOAD BALANCER - NETWORK LOAD BALANCER
# =========================================================================
resource "aws_lb" "locker_nlb" {
  name               = "${local.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [local.locker_subnet_id]
  security_groups    = [aws_security_group.nlb.id]

  tags = local.common_tags
}

# =========================================================================
# LOAD BALANCER - TARGET GROUP
# =========================================================================
resource "aws_lb_target_group" "locker" {
  name     = "${local.name_prefix}-tg"
  port     = var.locker_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    port     = var.locker_port
    protocol = "TCP"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "locker" {
  count = var.instance_count

  target_group_arn = aws_lb_target_group.locker.arn
  target_id        = module.locker_instance[count.index].id
  port             = var.locker_port
}

# =========================================================================
# LOAD BALANCER - LISTENERS
# =========================================================================
resource "aws_lb_listener" "locker" {
  for_each = var.nlb_listeners

  load_balancer_arn = aws_lb.locker_nlb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn != null ? each.value.target_group_arn : aws_lb_target_group.locker.arn
  }
}

module "database" {
  count = var.create_locker_database ? 1 : 0

  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database?ref=database-v0.1.1"

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
