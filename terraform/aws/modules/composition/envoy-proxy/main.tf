# =========================================================================
# SSH Key Pair for Envoy Instances
# =========================================================================

# Generate RSA key pair for SSH access
resource "tls_private_key" "envoy" {
  count = var.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "envoy_key_pair" {
  count = var.generate_ssh_key ? 1 : 0

  key_name   = "${local.name_prefix}-keypair-${data.aws_region.current.name}"
  public_key = tls_private_key.envoy[0].public_key_openssh

  tags = local.common_tags
}

# Save private key to AWS Systems Manager Parameter Store
# This allows you to retrieve the key later for SSH access if needed
resource "aws_ssm_parameter" "envoy_private_key" {
  count = var.generate_ssh_key ? 1 : 0

  name        = "/ec2/keypair/${aws_key_pair.envoy_key_pair[0].key_pair_id}"
  description = "Private SSH key for ${local.name_prefix} instances"
  type        = "SecureString"
  value       = tls_private_key.envoy[0].private_key_pem

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-key"
    }
  )
}

# Note: Private key is saved to Parameter Store for later retrieval
# Retrieve it with:
#   aws ssm get-parameter --name "/ec2/keypair/<key-pair-id>" --with-decryption --query 'Parameter.Value' --output text > envoy-keypair.pem
#   chmod 400 envoy-keypair.pem
#
# Recommended: Use AWS Systems Manager Session Manager (SSM) to connect to instances instead of SSH
# If SSH is required, use the command above to retrieve the private key

# =========================================================================
# S3 Bucket for Envoy Logs
# =========================================================================
module "logs_bucket" {
  source = "../../base/s3-bucket"

  bucket_name       = "${local.name_prefix}-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy     = var.environment != "prod" ? true : false
  enable_versioning = false

  # Security best practices
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  sse_algorithm = "AES256"

  # Note: Lifecycle rules removed - manage log retention manually if needed
  lifecycle_rules = []

  tags = local.common_tags
}

# =========================================================================
# S3 Configuration Upload (Optional)
# =========================================================================
# Upload Envoy configuration files from local directory to S3 config bucket
# Only if upload_config_to_s3 is true

resource "aws_s3_object" "envoy_config_files" {
  for_each = var.upload_config_to_s3 ? fileset(var.config_files_source_path, "**") : []

  bucket = var.config_bucket_name
  key    = "envoy/${each.value}"

  # Use templated content for envoy.yaml, raw content for other files
  content = each.value == "envoy.yaml" ? local.envoy_config_content : file("${var.config_files_source_path}/${each.value}")
  etag    = each.value == "envoy.yaml" ? md5(local.envoy_config_content) : filemd5("${var.config_files_source_path}/${each.value}")

  tags = local.common_tags
}

# =========================================================================
# IAM Role for Envoy Instances (Conditional - Create only if needed)
# =========================================================================
module "envoy_iam_role" {
  count  = var.create_iam_role ? 1 : 0
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
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
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

    envoy-ssm-parameters = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath"
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = local.common_tags
}

# Reference to existing IAM role (if using existing)
data "aws_iam_role" "existing_envoy_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_iam_role_name
}

# =========================================================================
# Security Groups
# =========================================================================

# Security Group for Load Balancer (Only create if creating new ALB)
module "lb_security_group" {
  count  = var.create_lb ? 1 : 0
  source = "../../base/security-group"

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Envoy proxy Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      description = "Allow HTTP from CloudFront/Internet"
      from_port   = var.alb_http_listener_port
      to_port     = var.alb_http_listener_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # CloudFront uses dynamic IPs, use prefix list if needed
    },
    {
      description = "Allow HTTPS from CloudFront/Internet"
      from_port   = var.alb_https_listener_port
      to_port     = var.alb_https_listener_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # CloudFront uses dynamic IPs, use prefix list if needed
    }
  ]

  egress_rules = [
    {
      description = "Allow traffic to Envoy ASG instances"
      from_port   = var.envoy_traffic_port
      to_port     = var.envoy_traffic_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Will be restricted by ASG SG
    }
  ]

  tags = local.common_tags
}

# Security Group for Envoy ASG Instances
module "asg_security_group" {
  source = "../../base/security-group"

  name        = "${local.name_prefix}-asg-sg"
  description = "Security group for Envoy proxy ASG instances"
  vpc_id      = var.vpc_id

  ingress_rules = concat(
    [
      {
        description              = "Allow traffic from ALB to Envoy"
        from_port                = var.envoy_traffic_port
        to_port                  = var.envoy_traffic_port
        protocol                 = "tcp"
        # Use existing LB SG if provided, otherwise use the newly created one
        source_security_group_id = var.create_lb ? module.lb_security_group[0].sg_id : var.existing_lb_security_group_id
      }
    ],
    # Only add health check rule if port is different from traffic port
    var.envoy_health_check_port != var.envoy_traffic_port ? [
      {
        description              = "Allow health checks from ALB"
        from_port                = var.envoy_health_check_port
        to_port                  = var.envoy_health_check_port
        protocol                 = "tcp"
        source_security_group_id = var.create_lb ? module.lb_security_group[0].sg_id : var.existing_lb_security_group_id
      }
    ] : []
  )

  egress_rules = [
    {
      description = "Allow traffic to Istio Internal LB"
      from_port   = var.envoy_upstream_port
      to_port     = var.envoy_upstream_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]  # Will be restricted by Istio ALB SG
    },
    {
      description = "Allow HTTPS to S3 via VPC Gateway Endpoint"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS UDP"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow DNS TCP"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = local.common_tags
}

# =========================================================================
# Security Group Rules: Allow Existing ALB to communicate with ASG
# =========================================================================
# When using an existing ALB, add egress rules to the existing ALB's security group
# to allow traffic to the new ASG security group

# Rule for traffic to Envoy ASG
resource "aws_security_group_rule" "existing_lb_to_asg_traffic" {
  count = var.create_lb ? 0 : 1  # Only create when using existing ALB

  type                     = "egress"
  from_port                = var.envoy_traffic_port
  to_port                  = var.envoy_traffic_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.sg_id
  security_group_id        = var.existing_lb_security_group_id

  description = "Allow traffic to Envoy ASG instances"
}

# Rule for health checks (only if different port)
resource "aws_security_group_rule" "existing_lb_to_asg_healthcheck" {
  count = var.create_lb ? 0 : (var.envoy_health_check_port != var.envoy_traffic_port ? 1 : 0)

  type                     = "egress"
  from_port                = var.envoy_health_check_port
  to_port                  = var.envoy_health_check_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.sg_id
  security_group_id        = var.existing_lb_security_group_id

  description = "Health check to Envoy ASG instances"
}

# =========================================================================
# Application Load Balancer (Conditional - Create only if needed)
# =========================================================================
# External ALB sits between CloudFront and Envoy ASG
# Architecture: CloudFront → External ALB → Envoy ASG → Internal ALB → EKS
resource "aws_lb" "envoy" {
  count = var.create_lb ? 1 : 0

  name               = "${local.name_prefix}-alb"
  internal           = false  # Public-facing to receive from CloudFront
  load_balancer_type = "application"
  subnets            = var.lb_subnet_ids
  security_groups    = [module.lb_security_group[0].sg_id]

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

# =========================================================================
# Target Group (Conditional - Create only if needed)
# =========================================================================
# Target group for ALB → Envoy ASG
# Targets Envoy traffic listener port
module "target_group" {
  count  = var.create_target_group ? 1 : 0
  source = "../../base/target-group"

  name        = "${local.name_prefix}-tg"
  port        = var.envoy_traffic_port
  protocol    = "HTTP"  # ALB uses HTTP protocol
  vpc_id      = var.vpc_id
  target_type = "instance"

  deregistration_delay = 30

  health_check = {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    port                = tostring(var.envoy_health_check_port)  # Dedicated health check port
    protocol            = "HTTP"
    path                = "/healthz"  # Envoy health check endpoint
    matcher             = "200"       # Expect 200 OK response
  }

  tags = local.common_tags
}

# =========================================================================
# Load Balancer Listeners (Create only if creating new ALB)
# =========================================================================
# HTTP Listener - Main traffic from CloudFront
resource "aws_lb_listener" "envoy_http" {
  count = var.create_lb ? 1 : 0

  load_balancer_arn = aws_lb.envoy[0].arn
  port              = var.alb_http_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn
  }

  tags = local.common_tags
}

# HTTPS Listener - Optional, requires SSL certificate
# Uncomment if you want to terminate SSL at ALB
# resource "aws_lb_listener" "envoy_https" {
#   count = var.create_lb ? 1 : 0
#
#   load_balancer_arn = aws_lb.envoy[0].arn
#   port              = var.alb_https_listener_port
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = var.ssl_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn
#   }
#
#   tags = local.common_tags
# }

# =========================================================================
# Launch Template (Conditional - Create only if not using existing)
# =========================================================================
module "launch_template" {
  count  = var.use_existing_launch_template ? 0 : 1
  source = "../../base/launch-template"

  name               = local.name_prefix
  description        = "Launch template for Envoy proxy instances - Config: ${substr(md5(local.envoy_config_content), 0, 8)}"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.generate_ssh_key ? aws_key_pair.envoy_key_pair[0].key_name : var.key_name
  security_group_ids = [module.asg_security_group.sg_id]

  iam_instance_profile_name = local.instance_profile_name

  user_data = base64encode(local.userdata_content)

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

  # Ensure S3 config files are uploaded before ASG starts
  depends_on = [aws_s3_object.envoy_config_files]

  name                      = "${local.name_prefix}-asg"
  launch_template_id        = local.launch_template_id
  launch_template_version   = local.launch_template_version
  subnet_ids                = var.proxy_subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  target_group_arns         = [var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  # Instance Refresh Configuration
  enable_instance_refresh      = var.enable_instance_refresh
  instance_refresh_preferences = var.instance_refresh_preferences
  instance_refresh_triggers    = var.instance_refresh_triggers

  tags          = local.common_tags
  instance_tags = merge(
    local.instance_tags,
    {
      # This tag changes when config changes, triggering instance refresh
      ConfigVersion = substr(md5(local.envoy_config_content), 0, 8)
    }
  )
}

# =========================================================================
# Instance Refresh Configuration
# =========================================================================
# This resource triggers rolling replacement of instances when config changes

resource "aws_autoscaling_group_tag" "config_version" {
  autoscaling_group_name = module.asg.asg_name

  tag {
    key                 = "ConfigVersion"
    value               = substr(md5(local.envoy_config_content), 0, 8)
    propagate_at_launch = true
  }
}

# Enable instance refresh on the ASG
resource "null_resource" "enable_instance_refresh" {
  count = var.enable_instance_refresh ? 1 : 0

  triggers = {
    config_version = substr(md5(local.envoy_config_content), 0, 8)
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws autoscaling start-instance-refresh \
        --auto-scaling-group-name ${module.asg.asg_name} \
        --preferences '{"MinHealthyPercentage":50,"InstanceWarmup":60}' \
        --region ${data.aws_region.current.name} || true
    EOT
  }

  depends_on = [module.asg]
}
