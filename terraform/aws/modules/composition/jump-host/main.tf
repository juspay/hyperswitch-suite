# CloudWatch Log Group for jump host logs
resource "aws_cloudwatch_log_group" "jump_host" {
  for_each = toset(["external", "internal"])

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
  inline_policy_permissions = {
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
  }

  tags = local.common_tags
}

# IAM Role for Internal Jump Host (No SSM Session Manager)
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
  policies = {
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  # Inline policies
  create_inline_policy = true
  inline_policy_permissions = {
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
  }

  tags = local.common_tags
}

# Security Group for External Jump Host (with rules)
module "external_jump_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.external_name_prefix}-sg"
  use_name_prefix = false
  description     = "Security group for external jump host"
  vpc_id          = var.vpc_id

  # Egress rule to internal jump host on SSH
  egress_with_source_security_group_id = [
    {
      description              = "Allow SSH to internal jump host"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.internal_jump_sg.security_group_id
    }
  ]

  # Egress rules with CIDR blocks
  egress_with_cidr_blocks = [
    {
      description = "Allow HTTPS for Session Manager and package downloads"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow HTTP for package downloads"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.external_name_prefix}-sg"
    }
  )
}

# Security Group for Internal Jump Host (with rules)
module "internal_jump_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${local.internal_name_prefix}-sg"
  use_name_prefix = false
  description     = "Security group for internal jump host"
  vpc_id          = var.vpc_id

  # Ingress rule from external jump host on SSH
  ingress_with_source_security_group_id = [
    {
      description              = "Allow SSH from external jump host only"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.external_jump_sg.security_group_id
    }
  ]

  # TODO: Add only database and redis ports as egress rules after they are defined.
  # Egress rule to allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.internal_name_prefix}-sg"
    }
  )
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

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [module.internal_jump_sg.security_group_id]
  iam_instance_profile   = module.internal_jump_iam_role.instance_profile_name
  key_name               = aws_key_pair.internal_jump.key_name

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

  name = local.external_name_prefix

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [module.external_jump_sg.security_group_id]
  iam_instance_profile   = module.external_jump_iam_role.instance_profile_name

  associate_public_ip_address = true
  monitoring                  = true
  user_data_base64 = base64encode(templatefile("${path.module}/templates/userdata.sh", {
    jump_type         = "external"
    environment       = var.environment
    cloudwatch_region = data.aws_region.current.id
    internal_jump_ip  = module.internal_jump_instance.private_ip
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
