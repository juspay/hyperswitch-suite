# CloudWatch Log Group for jump host logs
resource "aws_cloudwatch_log_group" "jump_host" {
  name              = "/aws/ec2/jump-host/${var.environment}-${var.project_name}/jump"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )
}

# =========================================================================
# SSM Session Manager Logging Resources
# =========================================================================

resource "aws_cloudwatch_log_group" "ssm_session_logs" {
  count = var.create_ssm_cloudwatch_log_group && var.ssm_cloudwatch_logging_enabled ? 1 : 0

  name              = local.ssm_cloudwatch_log_group_name
  retention_in_days = var.ssm_cloudwatch_log_group_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-ssm-session-logs"
    }
  )
}

resource "aws_s3_bucket" "ssm_session_logs" {
  count = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled ? 1 : 0

  bucket = local.ssm_s3_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.environment}-${var.project_name}-ssm-session-logs"
      Environment = var.environment
      Purpose     = "SSMSessionLogs"
    }
  )
}

resource "aws_s3_bucket_versioning" "ssm_session_logs" {
  count  = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.ssm_session_logs[0].id

  versioning_configuration {
    status = var.ssm_s3_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ssm_session_logs" {
  count = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled && var.ssm_s3_bucket_lifecycle_days > 0 ? 1 : 0

  bucket = aws_s3_bucket.ssm_session_logs[0].id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      days          = var.ssm_s3_bucket_lifecycle_days
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = var.ssm_s3_bucket_lifecycle_days
      storage_class   = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ssm_session_logs" {
  count = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.ssm_session_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ssm_session_logs" {
  count = var.create_ssm_s3_bucket && var.ssm_s3_logging_enabled ? 1 : 0

  bucket = aws_s3_bucket.ssm_session_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =========================================================================
# SSM Session Manager Preferences
# =========================================================================
resource "aws_ssm_document" "session_preferences" {
  count = var.create_ssm_session_preferences ? 1 : 0

  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session preferences for ${var.project_name} ${var.environment} jump host"
    sessionType   = "Standard_Stream"
    inputs = merge(
      {
        idleSessionTimeout          = tostring(var.ssm_idle_session_timeout)
        runAsEnabled                = var.ssm_run_as_user != ""
        cloudWatchEncryptionEnabled = var.ssm_cloudwatch_logging_enabled
        s3EncryptionEnabled         = var.ssm_s3_logging_enabled
        shellProfile = {
          linux   = var.ssm_shell_profile_linux
          windows = var.ssm_shell_profile_windows
        }
      },
      var.ssm_max_session_duration != "" ? { maxSessionDuration = var.ssm_max_session_duration } : {},
      var.ssm_run_as_user != "" ? { runAsDefaultUser = var.ssm_run_as_user } : {},
      var.enable_ssm_session_encryption ? { kmsKeyId = "alias/aws/ssm" } : {},
      var.ssm_cloudwatch_logging_enabled ? { cloudWatchLogGroupName = local.ssm_cloudwatch_log_group_name } : {},
      var.ssm_s3_logging_enabled ? { s3BucketName = local.ssm_s3_bucket_name } : {},
      var.ssm_s3_logging_enabled && var.ssm_s3_key_prefix != "" ? { s3KeyPrefix = var.ssm_s3_key_prefix } : {}
    )
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-ssm-session-preferences"
    }
  )
}

# =========================================================================
# IAM Role for Jump Host
# =========================================================================
module "jump_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.2"

  name                    = "${local.name_prefix}-role"
  create_instance_profile = true

  trust_policy_permissions = {
    EC2AssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }]
    }
  }

  policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

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
        resources = ["arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/jump-host/${var.environment}-${var.project_name}/jump*"]
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

# =========================================================================
# Security Group for Jump Host
# =========================================================================
module "jump_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.name_prefix}-sg"
  use_name_prefix = false
  description     = "Security group for jump host"
  vpc_id          = var.vpc_id

  egress_rules = ["all-all"]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-sg"
    }
  )
}

# =========================================================================
# Jump Host Instance
# =========================================================================
module "jump_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = local.name_prefix

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [module.jump_sg.security_group_id]
  iam_instance_profile   = module.jump_iam_role.instance_profile_name

  create_security_group = false

  associate_public_ip_address = false
  monitoring                  = true
  user_data_base64            = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.id
  }))

  root_block_device = {
    size                  = var.root_volume_size
    type                  = var.root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name     = local.name_prefix
      JumpType = "jump"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.jump_host
  ]
}
