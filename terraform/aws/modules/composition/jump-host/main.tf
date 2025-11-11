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

# IAM Role for Jump Host
module "jump_host_iam_role" {
  source = "../../base/iam-role"

  name                    = "${var.environment}-${var.project_name}-jump-host-role"
  service_identifiers     = ["ec2.amazonaws.com"]
  create_instance_profile = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  inline_policies = {
    jump-host-cloudwatch-logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/jump-host/${var.environment}/*"
        }
      ]
    })
  }

  tags = local.common_tags
}

# Security Group for External Jump Host
module "external_jump_sg" {
  source = "../../base/security-group"

  name        = "${local.external_name_prefix}-sg"
  description = "Security group for external jump host"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.external_name_prefix}-sg"
    }
  )
}

# Security Group for Internal Jump Host
module "internal_jump_sg" {
  source = "../../base/security-group"

  name        = "${local.internal_name_prefix}-sg"
  description = "Security group for internal jump host"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.internal_name_prefix}-sg"
    }
  )
}

# Security Group Rules for External Jump Host
module "external_jump_sg_rules" {
  source = "../../base/security-group-rules"

  security_group_id = module.external_jump_sg.sg_id

  rules = [
    {
      type        = "egress"
      description = "Allow SSH to internal jump host"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr        = null
      sg_id       = [module.internal_jump_sg.sg_id]
    },
    {
      type        = "egress"
      description = "Allow HTTPS for Session Manager and package downloads"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
      sg_id       = null
    },
    {
      type        = "egress"
      description = "Allow HTTP for package downloads"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr        = ["0.0.0.0/0"]
      sg_id       = null
    }
  ]
}

# Security Group Rules for Internal Jump Host
module "internal_jump_sg_rules" {
  source = "../../base/security-group-rules"

  security_group_id = module.internal_jump_sg.sg_id

  rules = concat(
    [
      {
        type        = "ingress"
        description = "Allow SSH from external jump host only"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr        = null
        sg_id       = [module.external_jump_sg.sg_id]
      }
    ],
    [
      {
        type        = "egress"
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr        = ["0.0.0.0/0"]
        sg_id       = null
      }
    ]
  )
}

# External Jump Host Instance
module "external_jump_instance" {
  source = "../../base/ec2-instance"

  name                        = local.external_name_prefix
  ami_id                      = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  security_group_ids          = [module.external_jump_sg.sg_id]
  iam_instance_profile_name   = module.jump_host_iam_role.instance_profile_name
  associate_public_ip_address = true
  monitoring                  = true
  user_data                   = local.userdata_external

  root_volume_size      = var.root_volume_size
  root_volume_type      = var.root_volume_type
  root_volume_encrypted = true

  tags = merge(
    local.common_tags,
    {
      Name     = local.external_name_prefix
      JumpType = "external"
    }
  )

  depends_on = [aws_cloudwatch_log_group.jump_host]
}

# Internal Jump Host Instance
module "internal_jump_instance" {
  source = "../../base/ec2-instance"

  name                        = local.internal_name_prefix
  ami_id                      = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  security_group_ids          = [module.internal_jump_sg.sg_id]
  iam_instance_profile_name   = module.jump_host_iam_role.instance_profile_name
  associate_public_ip_address = false
  monitoring                  = true
  user_data                   = local.userdata_internal

  root_volume_size      = var.root_volume_size
  root_volume_type      = var.root_volume_type
  root_volume_encrypted = true

  tags = merge(
    local.common_tags,
    {
      Name     = local.internal_name_prefix
      JumpType = "internal"
    }
  )

  depends_on = [aws_cloudwatch_log_group.jump_host]
}
