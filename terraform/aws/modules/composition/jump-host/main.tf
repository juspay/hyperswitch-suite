# CloudWatch Log Group for jump host logs
resource "aws_cloudwatch_log_group" "jump_host" {
  name              = "/aws/ec2/jump-host/${var.environment}/external"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-${var.project_name}-external-jump-logs"
    }
  )
}

# IAM Role for External Jump Host
module "external_jump_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.2"

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
    } : {},
    var.enable_fleet_manager ? {
      FleetManagerUserManagement = {
        sid    = "FleetManagerUserManagement"
        effect = "Allow"
        actions = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetConnectionStatus",
          "ssm:DescribeInstanceProperties",
          "ec2:DescribeInstances"
        ]
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

# Default egress for HTTPS (Session Manager, package downloads)
resource "aws_security_group_rule" "external_jump_default_egress_https" {
  security_group_id = module.external_jump_sg.security_group_id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS for Session Manager and package downloads"
}

# External Jump Host Instance
module "external_jump_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name = local.external_name_prefix

  ami                    = local.external_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [module.external_jump_sg.security_group_id]
  iam_instance_profile   = module.external_jump_iam_role.instance_profile_name

  create_security_group = false

  associate_public_ip_address = true
  monitoring                  = true
  user_data_base64 = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.id
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
  ]
}
