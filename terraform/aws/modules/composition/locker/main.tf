resource "aws_security_group" "locker" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for locker instance"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# =========================================================================
# Locker Instance - Ingress Rules
# =========================================================================
resource "aws_security_group_rule" "locker_ingress_ssh" {
  security_group_id        = aws_security_group.locker.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.jump_host_security_group_id
  description              = "SSH access from jump host"
}

resource "aws_security_group_rule" "locker_ingress_app" {
  security_group_id = aws_security_group.locker.id
  type            = "ingress"
  from_port       = 8080
  to_port         = 8080
  protocol        = "tcp"
  self            = true
  description     = "Application access from internal services"
}

# =========================================================================
# Locker Instance - Egress Rules
# =========================================================================
resource "aws_security_group_rule" "locker_egress_rds" {
  security_group_id = aws_security_group.locker.id
  type            = "egress"
  from_port       = 5432
  to_port         = 5432
  protocol        = "tcp"
  cidr_blocks     = [var.rds_cidr]
  description     = "Database access to RDS"
}

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

resource "aws_iam_policy" "locker" {
  name = "${local.name_prefix}-policy"
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

resource "aws_iam_role_policy_attachment" "locker" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker.arn
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

# Custom ECR Policy
resource "aws_iam_policy" "locker_ecr" {
  name = "${local.name_prefix}-ecr-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "0"
        Effect    = "Allow"
        Action    = "ecr:*"
        Resource  = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Custom KMS Policy
resource "aws_iam_policy" "locker_kms" {
  name = "${local.name_prefix}-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "0"
        Effect    = "Allow"
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

# Custom Policy Attachments
resource "aws_iam_role_policy_attachment" "locker_ecr" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker_ecr.arn
}

resource "aws_iam_role_policy_attachment" "locker_kms" {
  role       = aws_iam_role.locker.name
  policy_arn = aws_iam_policy.locker_kms.arn
}

module "locker_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.1.5"

  name = "${local.name_prefix}-instance"

  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = true
  subnet_id                   = var.locker_subnet_id
  vpc_security_group_ids      = [aws_security_group.locker.id]

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.locker.name

  # Deploy Docker container with pre-built card vault application
  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh", {}))


  tags = local.common_tags
}