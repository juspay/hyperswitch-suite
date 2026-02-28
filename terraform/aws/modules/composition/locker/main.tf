# =========================================================================
# DATA SOURCES
# =========================================================================
data "aws_availability_zones" "available" {
  count = var.create ? 1 : 0

  state = "available"
}

# =========================================================================
# NETWORK RESOURCES
# =========================================================================
resource "aws_subnet" "locker" {
  count             = var.create && var.create_subnet ? 1 : 0
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.subnet_availability_zone != null ? var.subnet_availability_zone : try(data.aws_availability_zones.available[0].names[0], "")

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
  count     = var.create && var.create_key_pair && var.public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (from provided or generated public key)
resource "aws_key_pair" "locker" {
  count      = var.create && var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = var.public_key != null ? var.public_key : try(tls_private_key.locker[0].public_key_openssh, "")

  tags = local.common_tags
}

# Store auto-generated private key in SSM Parameter Store
resource "aws_ssm_parameter" "locker_private_key" {
  count       = var.create && var.create_key_pair && var.public_key == null ? 1 : 0
  name        = "/${var.environment}/${var.project_name}/locker/ssh-private-key"
  description = "Auto-generated SSH private key for locker instance"
  type        = "SecureString"
  value       = try(tls_private_key.locker[0].private_key_pem, "")

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
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

  security_group_id        = try(aws_security_group.locker[0].id, "")
  type                     = "ingress"
  from_port                = var.locker_port
  to_port                  = var.locker_port
  protocol                 = "tcp"
  source_security_group_id = try(aws_security_group.nlb[0].id, "")
  description              = "Allow traffic from NLB to locker instance"
}

# =========================================================================
# SECURITY - NLB SECURITY GROUP
# =========================================================================
resource "aws_security_group" "nlb" {
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

  security_group_id        = try(aws_security_group.nlb[0].id, "")
  type                     = "egress"
  from_port                = var.locker_port
  to_port                  = var.locker_port
  protocol                 = "tcp"
  source_security_group_id = try(aws_security_group.locker[0].id, "")
  description              = "Allow NLB to send traffic to locker instance"
}

# =========================================================================
# MONITORING - CLOUDWATCH LOGS
# =========================================================================
resource "aws_cloudwatch_log_group" "locker" {
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

  name = "${local.name_prefix}-profile"
  role = try(aws_iam_role.locker[0].name, "")

  tags = local.common_tags
}

# =========================================================================
# IAM - CUSTOM POLICIES
# =========================================================================
# CloudWatch Logs Policy
resource "aws_iam_policy" "locker_logs" {
  count = var.create ? 1 : 0

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
        Resource = [try(aws_cloudwatch_log_group.locker[0].arn, "")]
      }
    ]
  })

  tags = local.common_tags
}

# ECR Policy
resource "aws_iam_policy" "locker_ecr" {
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

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
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = try(aws_iam_policy.locker_logs[0].arn, "")
}

resource "aws_iam_role_policy_attachment" "locker_ecr" {
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = try(aws_iam_policy.locker_ecr[0].arn, "")
}

resource "aws_iam_role_policy_attachment" "locker_kms" {
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = try(aws_iam_policy.locker_kms[0].arn, "")
}

# AWS Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "s3_fullaccess" {
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.create ? 1 : 0

  role       = try(aws_iam_role.locker[0].name, "")
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# =========================================================================
# COMPUTE - EC2 INSTANCES
# =========================================================================
module "locker_instance" {
  count = var.create ? var.instance_count : 0

  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.5"

  name = "${local.name_prefix}-instance-${count.index}"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_name
  monitoring                  = true
  subnet_id                   = local.locker_subnet_id
  vpc_security_group_ids      = [try(aws_security_group.locker[0].id, "")]
  associate_public_ip_address = false
  iam_instance_profile        = try(aws_iam_instance_profile.locker[0].name, "")
  create_security_group       = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-${count.index}"
  })
}

# =========================================================================
# LOAD BALANCER - NETWORK LOAD BALANCER
# =========================================================================
resource "aws_lb" "locker_nlb" {
  count = var.create ? 1 : 0

  name               = "${local.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [local.locker_subnet_id]
  security_groups    = [try(aws_security_group.nlb[0].id, "")]

  tags = local.common_tags
}

# =========================================================================
# LOAD BALANCER - TARGET GROUP
# =========================================================================
resource "aws_lb_target_group" "locker" {
  count = var.create ? 1 : 0

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
  count            = var.create ? var.instance_count : 0

  target_group_arn = try(aws_lb_target_group.locker[0].arn, "")
  target_id        = module.locker_instance[count.index].id
  port             = var.locker_port
}

# =========================================================================
# LOAD BALANCER - LISTENERS
# =========================================================================
resource "aws_lb_listener" "locker" {
  for_each = var.create ? var.nlb_listeners : {}

  load_balancer_arn = try(aws_lb.locker_nlb[0].arn, "")
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn != null ? each.value.target_group_arn : try(aws_lb_target_group.locker[0].arn, "")
  }
}
