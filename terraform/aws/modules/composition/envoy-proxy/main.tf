# =========================================================================
# S3 Bucket for Envoy Logs
# =========================================================================
module "logs_bucket" {
  source = "../../base/s3-bucket"

  bucket_name       = "${local.name_prefix}-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy     = var.environment != "prod" ? true : false
  enable_versioning = false

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  sse_algorithm = "AES256"

  lifecycle_rules = [
    {
      id              = "delete-old-logs"
      enabled         = true
      prefix          = ""
      expiration_days = var.environment == "prod" ? 90 : 30
      transition = [
        {
          days          = var.environment == "prod" ? 30 : 7
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
    }
  ]

  tags = local.common_tags
}

# =========================================================================
# IAM Role for Envoy Instances
# =========================================================================
module "envoy_iam_role" {
  source = "../../base/iam-role"

  name                    = "${local.name_prefix}-role"
  description             = "IAM role for Envoy proxy instances"
  service_identifiers     = ["ec2.amazonaws.com"]
  create_instance_profile = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  inline_policies = {
    envoy-config-bucket-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = [
            var.config_bucket_arn,
            "${var.config_bucket_arn}/*"
          ]
        }
      ]
    })

    envoy-logs-bucket-write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:PutObjectAcl",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = [
            module.logs_bucket.bucket_arn,
            "${module.logs_bucket.bucket_arn}/*"
          ]
        }
      ]
    })
  }

  tags = local.common_tags
}

# =========================================================================
# Security Groups
# =========================================================================
module "lb_security_group" {
  source = "../../base/security-group"

  name        = "${local.name_prefix}-lb-sg"
  description = "Security group for Envoy proxy load balancer"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      description              = "Allow traffic from EKS cluster"
      from_port                = var.envoy_listener_port
      to_port                  = var.envoy_listener_port
      protocol                 = "tcp"
      source_security_group_id = var.eks_security_group_id
    }
  ]

  egress_rules = [
    {
      description = "Allow traffic to Envoy ASG instances"
      from_port   = var.envoy_listener_port
      to_port     = var.envoy_listener_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = local.common_tags
}

module "asg_security_group" {
  source = "../../base/security-group"

  name        = "${local.name_prefix}-asg-sg"
  description = "Security group for Envoy proxy ASG instances"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      description              = "Allow traffic from Load Balancer"
      from_port                = var.envoy_listener_port
      to_port                  = var.envoy_listener_port
      protocol                 = "tcp"
      source_security_group_id = module.lb_security_group.sg_id
    },
    {
      description              = "Allow admin traffic from Load Balancer"
      from_port                = var.envoy_admin_port
      to_port                  = var.envoy_admin_port
      protocol                 = "tcp"
      source_security_group_id = module.lb_security_group.sg_id
    }
  ]

  egress_rules = [
    {
      description = "Allow HTTP to internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTPS to internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = local.common_tags
}

# =========================================================================
# Network Load Balancer
# =========================================================================
resource "aws_lb" "envoy" {
  name               = "${local.name_prefix}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.lb_subnet_ids
  security_groups    = [module.lb_security_group.sg_id]

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_cross_zone_load_balancing = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-nlb"
    }
  )
}

# =========================================================================
# Target Group
# =========================================================================
module "target_group" {
  source = "../../base/target-group"

  name        = "${local.name_prefix}-tg"
  port        = var.envoy_listener_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = 30

  health_check = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    port                = var.envoy_admin_port
    protocol            = "HTTP"
    path                = "/ready"
  }

  tags = local.common_tags
}

# =========================================================================
# Load Balancer Listener
# =========================================================================
resource "aws_lb_listener" "envoy" {
  load_balancer_arn = aws_lb.envoy.arn
  port              = var.envoy_listener_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = module.target_group.tg_arn
  }

  tags = local.common_tags
}

# =========================================================================
# Launch Template
# =========================================================================
module "launch_template" {
  source = "../../base/launch-template"

  name               = local.name_prefix
  description        = "Launch template for Envoy proxy instances"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
  security_group_ids = [module.asg_security_group.sg_id]

  iam_instance_profile_name = module.envoy_iam_role.instance_profile_name

  user_data = local.userdata_content

  ebs_optimized     = true
  enable_monitoring = var.enable_detailed_monitoring

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size           = var.root_volume_size
        volume_type           = var.root_volume_type
        delete_on_termination = true
        encrypted             = true
      }
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = local.instance_tags
    },
    {
      resource_type = "volume"
      tags          = local.instance_tags
    }
  ]

  tags = local.common_tags
}

# =========================================================================
# Auto Scaling Group
# =========================================================================
module "asg" {
  source = "../../base/asg"

  name                      = "${local.name_prefix}-asg"
  launch_template_id        = module.launch_template.lt_id
  launch_template_version   = "$Latest"
  subnet_ids                = var.proxy_subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  target_group_arns         = [module.target_group.tg_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  tags          = local.common_tags
  instance_tags = local.instance_tags
}
