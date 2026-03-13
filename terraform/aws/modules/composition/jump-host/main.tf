# CloudWatch Log Group for jump host logs
resource "aws_cloudwatch_log_group" "jump_host" {
  for_each = toset(var.enable_external_jump ? ["external", "internal"] : ["internal"])

  name              = "/aws/ec2/jump-host/${var.environment}/${each.key}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-${each.key}-jump-logs"
    }
  )
}

# Generate SSH key pair for internal jump access
resource "tls_private_key" "internal_jump" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in SSM Parameter Store
module "internal_jump_ssh_key_parameter" {
  source  = "terraform-aws-modules/ssm-parameter/aws"
  version = "~> 1.0"

  name        = "/jump-host/${var.environment}/internal/ssh-private-key"
  description = "Private SSH key for accessing internal jump host from external jump"
  type        = "SecureString"
  value       = tls_private_key.internal_jump.private_key_pem
  secure_type = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.internal_name_prefix}-ssh-key"
    }
  )
}
# =========================================================================
# SSM Session Manager Preferences
# =========================================================================
# This document is named SSM-SessionManagerRunShell which is the default
# document Session Manager uses for all sessions in this account/region.
# NOTE: This is an account-level setting. If multiple environments share
# the same AWS account, only one such document can exist. Use
# create_ssm_session_preferences = false to skip creation in environments
# that share an AWS account with another environment.
resource "aws_ssm_document" "session_preferences" {
  count = var.create_ssm_session_preferences ? 1 : 0

  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session preferences for ${var.project_name} ${var.environment} jump hosts"
    sessionType   = "Standard_Stream"
    inputs = {
      # Session timeout settings
      idleSessionTimeoutInMinutes = var.ssm_idle_session_timeout
      maxSessionDurationInMinutes = var.ssm_max_session_duration != "" ? tonumber(var.ssm_max_session_duration) : null

      # Run As configuration
      # When runAsEnabled=true and runAsDefaultUser is set (e.g., "ubuntu"),
      # SSM creates OS users based on IAM user name and runs sessions as that user
      runAsEnabled     = var.ssm_run_as_user != ""
      runAsDefaultUser = var.ssm_run_as_user != "" ? var.ssm_run_as_user : null

      # KMS encryption
      kmsKeyId = var.enable_ssm_session_encryption ? "alias/aws/ssm" : null

      # CloudWatch logging
      cloudWatchLogGroupName      = var.ssm_cloudwatch_logging_enabled && var.ssm_cloudwatch_log_group_name != "" ? var.ssm_cloudwatch_log_group_name : null
      cloudWatchEncryptionEnabled = var.ssm_cloudwatch_logging_enabled

      # S3 logging
      s3BucketName        = var.ssm_s3_logging_enabled && var.ssm_s3_bucket_name != "" ? var.ssm_s3_bucket_name : null
      s3KeyPrefix         = var.ssm_s3_logging_enabled && var.ssm_s3_key_prefix != "" ? var.ssm_s3_key_prefix : null
      s3EncryptionEnabled = var.ssm_s3_logging_enabled

      # Shell profile - commands that run when session starts
      shellProfile = {
        linux   = var.ssm_shell_profile_linux
        windows = var.ssm_shell_profile_windows
      }
    }
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-ssm-session-preferences"
    }
  )
}




# IAM Role for External Jump Host
module "external_jump_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.2"

  count = var.enable_external_jump ? 1 : 0

  name                    = "${var.environment}-${var.project_name}-external-jump-role"
  create_instance_profile = true

  # Trust policy for EC2
  trust_policy_permissions = {
    EC2AssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }]
    }
  }

  # Managed policies
  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Inline policies
  create_inline_policy = true
  inline_policy_permissions = merge(
    {
      CloudWatchLogs = {
        sid    = "CloudWatchLogs"
        effect = "Allow"
        actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/jump-host/${var.environment}/external*"]
      }
      SSMParameters = {
        sid    = "SSMParameters"
        effect = "Allow"
        actions = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        resources = ["arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/jump-host/${var.environment}/internal/*"]
      }
      S3PackerMigration = {
        sid    = "S3PackerMigration"
        effect = "Allow"
        actions = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        resources = [
          "arn:aws:s3:::packer-migration-temp-*",
          "arn:aws:s3:::packer-migration-temp-*/*"
        ]
      }
      KMSSessionEncryption = {
        sid    = "KMSSessionEncryption"
        effect = "Allow"
        actions = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        resources = [
          "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
      SSMSessionLogging = {
        sid    = "SSMSessionLogging"
        effect = "Allow"
        actions = [
          "s3:PutObject"
        ]
        resources = [
          "arn:aws:s3:::*/*"
        ]
      }
      SSMSessionLoggingEncryption = {
        sid       = "SSMSessionLoggingEncryption"
        effect    = "Allow"
        actions   = ["s3:GetEncryptionConfiguration"]
        resources = ["*"]
      }
    },
    var.enable_migration_mode ? {
      SSMCommands = {
        sid    = "SSMCommands"
        effect = "Allow"
        actions = [
          "ssm:DescribeInstanceInformation",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        resources = ["*"]
      }
    } : {}
  )

  tags = local.common_tags
}

# IAM Role for Internal Jump Host (Optional SSM Session Manager)
module "internal_jump_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.2"

  name                    = "${var.environment}-${var.project_name}-internal-jump-role"
  create_instance_profile = true

  # Trust policy for EC2
  trust_policy_permissions = {
    EC2AssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }]
    }
  }

  # Managed policies
  policies = merge(
    {
      CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    },
    local.internal_ssm_enabled ? {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    } : {}
  )

  # Inline policies
  create_inline_policy = true
  inline_policy_permissions = merge(
    {
      CloudWatchLogs = {
        sid    = "CloudWatchLogs"
        effect = "Allow"
        actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/jump-host/${var.environment}/internal*"]
      }
    },
    local.internal_ssm_enabled ? {
      KMSSessionEncryption = {
        sid    = "KMSSessionEncryption"
        effect = "Allow"
        actions = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        resources = [
          "arn:aws:kms:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:key/*"
        ]
      }
      SSMSessionLogging = {
        sid    = "SSMSessionLogging"
        effect = "Allow"
        actions = [
          "s3:PutObject"
        ]
        resources = [
          "arn:aws:s3:::*/*"
        ]
      }
      SSMSessionLoggingEncryption = {
        sid       = "SSMSessionLoggingEncryption"
        effect    = "Allow"
        actions   = ["s3:GetEncryptionConfiguration"]
        resources = ["*"]
      }
    } : {}
  )

  tags = local.common_tags
}

# Security Group for External Jump Host
module "external_jump_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  count = var.enable_external_jump ? 1 : 0

  name            = "${local.external_name_prefix}-sg"
  use_name_prefix = false
  description     = "Security group for external jump host"
  vpc_id          = var.vpc_id

  # Rules are managed separately below
  egress_rules  = []
  ingress_rules = []

  tags = merge(
    local.common_tags,
    {
      Name = "${local.external_name_prefix}-sg"
    }
  )
}

# Security Group for Internal Jump Host
module "internal_jump_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.internal_name_prefix}-sg"
  use_name_prefix = false
  description     = "Security group for internal jump host"
  vpc_id          = var.vpc_id

  # Rules are managed separately below
  egress_rules  = []
  ingress_rules = []

  tags = merge(
    local.common_tags,
    {
      Name = "${local.internal_name_prefix}-sg"
    }
  )
}


# =========================================================================
# External Jump Host - Default Egress Rules (Automatic)
# =========================================================================
# Default egress to internal jump on SSH
resource "aws_security_group_rule" "external_jump_default_egress_to_internal" {
  count = var.enable_external_jump ? 1 : 0

  security_group_id        = module.external_jump_sg[0].security_group_id
  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.internal_jump_sg.security_group_id
  description              = "Allow SSH to internal jump host"
}

# Default egress for HTTPS (Session Manager, package downloads)
resource "aws_security_group_rule" "external_jump_default_egress_https" {
  count = var.enable_external_jump ? 1 : 0

  security_group_id = module.external_jump_sg[0].security_group_id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS for Session Manager and package downloads"
}


# =========================================================================
# Internal Jump Host - Default Ingress Rules (Automatic)
# =========================================================================
# Default ingress from external jump on SSH (only when external jump is enabled)
resource "aws_security_group_rule" "internal_jump_default_ingress_from_external" {
  count = var.enable_external_jump ? 1 : 0

  security_group_id        = module.internal_jump_sg.security_group_id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.external_jump_sg[0].security_group_id
  description              = "Allow SSH from external jump host only"
}


# Create AWS key pair for internal jump (public key only)
resource "aws_key_pair" "internal_jump" {
  key_name   = "${local.internal_name_prefix}-keypair"
  public_key = tls_private_key.internal_jump.public_key_openssh

  tags = merge(
    local.common_tags,
    {
      Name = "${local.internal_name_prefix}-keypair"
    }
  )
}

# Internal Jump Host Instance (must be created first to get its IP)
module "internal_jump_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = local.internal_name_prefix

  ami                    = local.internal_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [module.internal_jump_sg.security_group_id]
  iam_instance_profile   = module.internal_jump_iam_role.instance_profile_name
  key_name               = aws_key_pair.internal_jump.key_name

  create_security_group = false

  associate_public_ip_address = false
  monitoring                  = true
  user_data_base64            = base64encode(local.userdata_internal)

  # Root volume configuration
  root_block_device = {
    size                  = var.root_volume_size
    type                  = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  # IMDSv2 is enabled by default in v5+

  tags = merge(
    local.common_tags,
    {
      Name     = local.internal_name_prefix
      JumpType = "internal"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.jump_host,
    aws_key_pair.internal_jump
  ]
}

# External Jump Host Instance (created after internal to get its IP)
module "external_jump_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  count = var.enable_external_jump ? 1 : 0

  name = local.external_name_prefix

  ami                    = local.external_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [module.external_jump_sg[0].security_group_id]
  iam_instance_profile   = module.external_jump_iam_role[0].instance_profile_name

  create_security_group = false

  associate_public_ip_address = true
  monitoring                  = true
  user_data_base64 = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    jump_type         = "external"
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.id
    internal_jump_ip  = module.internal_jump_instance.private_ip
    os_username       = var.ssm_os_username
  }))

  # Root volume configuration
  root_block_device = {
    size                  = var.root_volume_size
    type                  = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  # IMDSv2 is enabled by default in v5+

  tags = merge(
    local.common_tags,
    {
      Name     = local.external_name_prefix
      JumpType = "external"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.jump_host,
    module.internal_jump_instance,
    module.internal_jump_ssh_key_parameter
  ]
}
