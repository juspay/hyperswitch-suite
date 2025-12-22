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
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb.id
  description              = "Allow traffic from NLB to locker instance"
}

# Additional ingress rules (environment-configurable via ingress_rules variable)
resource "aws_security_group_rule" "locker_ingress_rules" {
  for_each = { for idx, rule in var.locker_ingress_rules : idx => rule }

  security_group_id = local.locker_security_group_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# LOCKER SECURITY GROUP - EGRESS RULES
# =========================================================================
# All egress rules are environment-configurable via egress_rules variable
resource "aws_security_group_rule" "locker_egress_rules" {
  for_each = { for idx, rule in var.locker_egress_rules : idx => rule }

  security_group_id = local.locker_security_group_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
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
# NLB SECURITY GROUP - INGRESS RULES
# =========================================================================
# All ingress rules are environment-configurable via nlb_ingress_rules variable
resource "aws_security_group_rule" "nlb_ingress_rules" {
  for_each = { for idx, rule in var.nlb_ingress_rules : idx => rule }

  security_group_id = aws_security_group.nlb.id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
}

# =========================================================================
# NLB SECURITY GROUP - EGRESS RULES
# =========================================================================
# Internal rule: Allow NLB to send traffic to locker instance (required for module functionality)
resource "aws_security_group_rule" "nlb_egress_to_locker" {
  security_group_id        = aws_security_group.nlb.id
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = local.locker_security_group_id
  description              = "Allow NLB to send traffic to locker instance"
}

# Additional egress rules (environment-configurable via nlb_egress_rules variable)
resource "aws_security_group_rule" "nlb_egress_rules" {
  for_each = { for idx, rule in var.nlb_egress_rules : idx => rule }

  security_group_id = aws_security_group.nlb.id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = try(each.value.cidr, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr, null)
  source_security_group_id = try(each.value.sg_id[0], null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
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
# COMPUTE - EC2 INSTANCE
# =========================================================================
module "locker_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.5"

  name = "${local.name_prefix}-instance"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = local.key_name
  monitoring                  = true
  subnet_id                   = local.locker_subnet_id
  vpc_security_group_ids      = [local.locker_security_group_id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.locker.name
  create_security_group       = false

  tags = local.common_tags
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
  port     = 8080
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    port     = "8080"
    protocol = "TCP"
  }

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "locker" {
  target_group_arn = aws_lb_target_group.locker.arn
  target_id        = module.locker_instance.id
  port             = 8080
}

# =========================================================================
# LOAD BALANCER - LISTENERS
# =========================================================================
resource "aws_lb_listener" "locker" {
  for_each = { for idx, listener in var.nlb_listeners : idx => listener }

  load_balancer_arn = aws_lb.locker_nlb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.target_group_arn != null ? each.value.target_group_arn : aws_lb_target_group.locker.arn
  }
}
