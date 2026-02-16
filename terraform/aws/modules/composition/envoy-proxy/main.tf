# =========================================================================
# SSH Key Pair for Envoy Instances
# =========================================================================
module "key_pair" {
  count   = var.generate_ssh_key ? 1 : 0
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name              = "${local.name_prefix}-keypair-${data.aws_region.current.name}"
  create_private_key    = true
  private_key_algorithm = "RSA"
  private_key_rsa_bits  = 4096

  tags = local.common_tags
}

# Save private key to AWS Systems Manager Parameter Store
# This allows you to retrieve the key later for SSH access if needed
resource "aws_ssm_parameter" "envoy_private_key" {
  count = var.generate_ssh_key ? 1 : 0

  name        = "/ec2/keypair/${module.key_pair[0].key_pair_id}"
  description = "Private SSH key for ${local.name_prefix} instances"
  type        = "SecureString"
  value       = module.key_pair[0].private_key_pem

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
# S3 Bucket for Envoy Logs (Optional - Create only if needed)
# =========================================================================
module "logs_bucket" {
  count   = var.create_logs_bucket ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "${local.name_prefix}-logs-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = var.environment != "prod" ? true : false

  # Versioning
  versioning = {
    enabled = false
  }

  # Security best practices - Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Note: Lifecycle rules removed - manage log retention manually if needed

  tags = local.common_tags
}

# =========================================================================
# S3 Bucket for Envoy Configuration (Optional - Create only if needed)
# =========================================================================
module "config_bucket" {
  count   = var.create_config_bucket ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "${local.name_prefix}-config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = var.environment != "prod" ? true : false

  # Versioning - Enable to track config changes
  versioning = {
    enabled = true
  }

  # Security best practices - Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.common_tags
}

# =========================================================================
# S3 Configuration Upload (Optional)
# =========================================================================
# Upload Envoy configuration files from local directory to S3 config bucket
# Only if upload_config_to_s3 is true
# Git is the source of truth - any changes to files will trigger re-upload

resource "aws_s3_object" "envoy_config_files" {
  for_each = var.upload_config_to_s3 ? fileset(var.config_files_source_path, "**") : []

  bucket = local.config_bucket_name
  key    = "envoy/${each.value}"

  # Use templated content for the specified config file, raw content for other files
  content = each.value == var.envoy_config_filename ? local.envoy_config_content : file("${var.config_files_source_path}/${each.value}")
  etag    = each.value == var.envoy_config_filename ? md5(local.envoy_config_content) : filemd5("${var.config_files_source_path}/${each.value}")

  tags = local.common_tags
}

# =========================================================================
# IAM Role for Envoy Instances (Conditional - Create only if needed)
# =========================================================================
module "envoy_iam_role" {
  count   = var.create_iam_role ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role             = true
  create_instance_profile = true

  role_name         = "${var.environment}-${var.project_name}-envoy-role"
  role_description  = "IAM role for Envoy proxy instances"
  role_requires_mfa = false

  trusted_role_services = ["ec2.amazonaws.com"]

  # Restrictive inline policies
  custom_role_policy_arns = []

  inline_policy_statements = [
    # CloudWatch - Restricted to PutMetricData only
    {
      sid    = "PutMetricData"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData"
      ]
      resources = ["*"]
    },
    # S3 Config Bucket - Read-only access
    {
      sid    = "ConfigBucketRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        local.config_bucket_arn,
        "${local.config_bucket_arn}/*"
      ]
    },
    # S3 Logs Bucket - Write access for log archival
    {
      sid    = "LogsBucketWrite"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:ListBucket"
      ]
      resources = [
        local.logs_bucket_arn,
        "${local.logs_bucket_arn}/*"
      ]
    }
  ]

  tags = local.common_tags
}

# Create a new instance profile for existing IAM role
# This allows you to reuse an existing IAM role but create a fresh instance profile
resource "aws_iam_instance_profile" "envoy_profile" {
  count = !var.create_iam_role && var.create_instance_profile ? 1 : 0

  name = "${local.name_prefix}-instance-profile"
  role = data.aws_iam_role.existing_envoy_role[0].name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance-profile"
    }
  )
}

# =========================================================================
# Security Groups
# =========================================================================

# Security Group for Load Balancer (Only create if creating new ALB)
module "lb_security_group" {
  count   = var.create_lb ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Envoy proxy Application Load Balancer"
  vpc_id      = var.vpc_id

  # Rules are managed separately
  egress_rules  = []
  ingress_rules = []

  tags = local.common_tags
}

# =========================================================================
# Load Balancer Security Group - Default Egress Rules (Automatic)
# =========================================================================
# Automatically allow traffic from LB to Envoy ASG on configured traffic port
# This rule is essential for LB → ASG communication and is created automatically
resource "aws_security_group_rule" "lb_default_egress_to_asg" {
  count = var.create_lb ? 1 : 0

  security_group_id        = module.lb_security_group[0].security_group_id
  type                     = "egress"
  from_port                = var.envoy_traffic_port
  to_port                  = var.envoy_traffic_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.security_group_id
  description              = "Allow traffic to Envoy ASG on traffic port"
}

# Security Group for Envoy ASG Instances
module "asg_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-asg-sg"
  description = "Security group for Envoy proxy ASG instances"
  vpc_id      = var.vpc_id

  # Rules are managed separately
  egress_rules  = []
  ingress_rules = []

  tags = local.common_tags
}

# =========================================================================
# ASG Security Group - Default Ingress Rules
# =========================================================================
# Allow traffic from ALB to Envoy (only if ALB security group is known)
resource "aws_security_group_rule" "asg_ingress_from_alb_traffic" {
  count = var.create_lb || var.existing_lb_security_group_id != null ? 1 : 0

  security_group_id        = module.asg_security_group.security_group_id
  type                     = "ingress"
  from_port                = var.envoy_traffic_port
  to_port                  = var.envoy_traffic_port
  protocol                 = "tcp"
  source_security_group_id = var.create_lb ? module.lb_security_group[0].security_group_id : var.existing_lb_security_group_id
  description              = "Allow traffic from ALB to Envoy"
}

# Allow health checks from ALB (only if different port and ALB security group is known)
resource "aws_security_group_rule" "asg_ingress_from_alb_healthcheck" {
  count = (var.create_lb || var.existing_lb_security_group_id != null) && var.health_check.port != var.envoy_traffic_port ? 1 : 0

  security_group_id        = module.asg_security_group.security_group_id
  type                     = "ingress"
  from_port                = var.health_check.port
  to_port                  = var.health_check.port
  protocol                 = "tcp"
  source_security_group_id = var.create_lb ? module.lb_security_group[0].security_group_id : var.existing_lb_security_group_id
  description              = "Allow health checks from ALB"
}

# =========================================================================
# Security Group Rules: Allow Existing ALB to communicate with ASG
# =========================================================================
# When using an existing ALB, add egress rules to the existing ALB's security group
# to allow traffic to the new ASG security group
# Only created if existing_lb_security_group_id is provided

# Rule for traffic to Envoy ASG
resource "aws_security_group_rule" "existing_lb_to_asg_traffic" {
  count = !var.create_lb && var.existing_lb_security_group_id != null ? 1 : 0

  type                     = "egress"
  from_port                = var.envoy_traffic_port
  to_port                  = var.envoy_traffic_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.security_group_id
  security_group_id        = var.existing_lb_security_group_id

  description = "Allow traffic to Envoy ASG instances"
}

# Rule for health checks (only if different port)
resource "aws_security_group_rule" "existing_lb_to_asg_healthcheck" {
  count = !var.create_lb && var.existing_lb_security_group_id != null && var.health_check.port != var.envoy_traffic_port ? 1 : 0

  type                     = "egress"
  from_port                = var.health_check.port
  to_port                  = var.health_check.port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.security_group_id
  security_group_id        = var.existing_lb_security_group_id

  description = "Health check to Envoy ASG instances"
}

# =========================================================================
# Application Load Balancer (Conditional - Create only if needed)
# =========================================================================
# External ALB sits between CloudFront and Envoy ASG
# Architecture: CloudFront → External ALB → Envoy ASG → Internal ALB → EKS
module "alb" {
  count   = var.create_lb ? 1 : 0
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false # Public-facing to receive from CloudFront

  vpc_id          = var.vpc_id
  subnets         = var.lb_subnet_ids
  security_groups = [module.lb_security_group[0].security_group_id]

  # ALB settings
  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true

  # We'll create target groups and listeners separately for more control
  create_security_group = false

  tags = local.common_tags
}

# =========================================================================
# Target Group (Conditional - Create only if needed)
# =========================================================================
# Target group for ALB → Envoy ASG
# Targets Envoy traffic listener port
resource "aws_lb_target_group" "envoy" {
  for_each = var.create_target_group ? local.target_groups : {}

  name                 = "${local.name_prefix}-tg-${substr(md5("${var.target_group_protocol}-${var.envoy_traffic_port}"), 0, 6)}"
  port                 = var.envoy_traffic_port
  protocol             = var.target_group_protocol # HTTP or HTTPS based on configuration
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.target_group_deregistration_delay

  health_check {
    enabled             = var.health_check.enabled
    port                = tostring(var.health_check.port)
    path                = var.health_check.path
    protocol            = var.health_check.protocol
    matcher             = var.health_check.matcher
    interval            = var.health_check.interval
    timeout             = var.health_check.timeout
    healthy_threshold   = var.health_check.healthy_threshold
    unhealthy_threshold = var.health_check.unhealthy_threshold
  }

  tags = merge(
    local.common_tags,
    {
      Name       = "${local.name_prefix}-tg-${each.key}"
      Deployment = "${each.value}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =========================================================================
# Load Balancer Listeners (Create only if creating new ALB)
# =========================================================================

# HTTP Listener - Conditional behavior based on HTTPS configuration
resource "aws_lb_listener" "envoy_http" {
  count = var.create_lb ? 1 : 0

  load_balancer_arn = module.alb[0].arn
  port              = var.alb_http_listener_port
  protocol          = "HTTP"

  # If HTTPS is enabled and redirect is configured, redirect to HTTPS
  # Otherwise, forward to target group
  default_action {
    type = var.enable_https_listener && var.enable_http_to_https_redirect ? "redirect" : "forward"

    # Redirect configuration (only used if type = "redirect")
    dynamic "redirect" {
      for_each = var.enable_https_listener && var.enable_http_to_https_redirect ? [1] : []
      content {
        port        = tostring(var.alb_https_listener_port)
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # Weighted Forward block (used only when not redirecting)
    dynamic "forward" {
      for_each = !(var.enable_https_listener && var.enable_http_to_https_redirect) ? [1] : []
      content {

        # Canary target group (optional)
        dynamic "target_group" {
          for_each = local.deployments
          content {
            arn    = each.value.target_group_arns[0]
            weight = each.value.weight
          }
        }

        stickiness {
          enabled  = false
          duration = 1
        }
      }
    }
  }

  tags = local.common_tags
}

# HTTPS Listener - SSL/TLS termination at ALB
resource "aws_lb_listener" "envoy_https" {
  count = var.create_lb && var.enable_https_listener ? 1 : 0

  load_balancer_arn = module.alb[0].arn
  port              = var.alb_https_listener_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type = "forward"

    forward {

      dynamic "target_group" {
        for_each = local.deployments
        content {
          arn    = each.value.target_group_arns[0]
          weight = each.value.weight
        }
      }

      stickiness {
        enabled  = false
        duration = 1
      }
    }
  }

  tags = local.common_tags
}

# =========================================================================
# Advanced Listener Rules (Header-based routing, path-based routing, etc.)
# =========================================================================
# Apply custom rules to HTTPS listener if enabled, otherwise to HTTP listener
resource "aws_lb_listener_rule" "custom_rules" {
  for_each = var.create_lb ? { for idx, rule in var.listener_rules : idx => rule } : {}

  listener_arn = var.enable_https_listener ? aws_lb_listener.envoy_https[0].arn : aws_lb_listener.envoy_http[0].arn
  priority     = each.value.priority

  # Actions
  dynamic "action" {
    for_each = each.value.actions
    content {
      type             = action.value.type
      target_group_arn = action.value.type == "forward" ? action.value.target_group_arn : null

      # Redirect action
      dynamic "redirect" {
        for_each = action.value.type == "redirect" && action.value.redirect != null ? [action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
        }
      }

      # Fixed response action
      dynamic "fixed_response" {
        for_each = action.value.type == "fixed-response" && action.value.fixed_response != null ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
    }
  }

  # Conditions
  dynamic "condition" {
    for_each = each.value.conditions
    content {
      # Host header condition
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? [condition.value.host_header] : []
        content {
          values = host_header.value.values
        }
      }

      # HTTP header condition
      dynamic "http_header" {
        for_each = condition.value.http_header != null ? [condition.value.http_header] : []
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      # Path pattern condition
      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? [condition.value.path_pattern] : []
        content {
          values = path_pattern.value.values
        }
      }

      # Source IP condition
      dynamic "source_ip" {
        for_each = condition.value.source_ip != null ? [condition.value.source_ip] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  tags = local.common_tags
}

# =========================================================================
# WAF Web ACL Association
# =========================================================================
resource "aws_wafv2_web_acl_association" "envoy_alb" {
  count = var.create_lb && var.enable_waf ? 1 : 0

  resource_arn = module.alb[0].arn
  web_acl_arn  = var.waf_web_acl_arn
}

# =========================================================================
# Launch Template (Conditional - Create only if not using existing)
# =========================================================================
resource "aws_launch_template" "envoy" {
  count = var.use_existing_launch_template ? 0 : 1

  name_prefix = "${local.name_prefix}-"
  description = "Launch template for Envoy proxy instances - Config: ${substr(md5(local.envoy_config_content), 0, 8)}"

  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.generate_ssh_key ? module.key_pair[0].key_pair_name : var.key_name
  vpc_security_group_ids = [module.asg_security_group.security_group_id]
  ebs_optimized          = var.ebs_optimized
  user_data              = base64encode(local.userdata_content)
  update_default_version = true

  iam_instance_profile {
    name = local.instance_profile_name
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  # Only include metadata_options if at least one IMDS setting is configured
  dynamic "metadata_options" {
    for_each = var.imds_http_endpoint != null || var.imds_http_tokens != null || var.imds_http_put_response_hop_limit != null || var.imds_instance_metadata_tags != null ? [1] : []
    content {
      http_endpoint               = var.imds_http_endpoint
      http_tokens                 = var.imds_http_tokens
      http_put_response_hop_limit = var.imds_http_put_response_hop_limit
      instance_metadata_tags      = var.imds_instance_metadata_tags
    }
  }

  # Conditional block device mapping - only add if enabled
  # If your AMI already has storage configured, set enable_ebs_block_device = false
  dynamic "block_device_mappings" {
    for_each = var.enable_ebs_block_device ? [1] : []
    content {
      device_name = "/dev/xvda"

      ebs {
        volume_size           = var.root_volume_size
        volume_type           = var.root_volume_type
        delete_on_termination = true
        encrypted             = var.ebs_encrypted
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.instance_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.instance_tags
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.name_prefix
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =========================================================================
# Auto Scaling Group
# =========================================================================
module "asg" {
  for_each = local.deployments

  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  # Ensure S3 config files are uploaded before ASG starts
  depends_on = [aws_s3_object.envoy_config_files, aws_launch_template.envoy]

  name = "${local.name_prefix}-asg"

  # =========================================================================
  # Launch Template Configuration Strategy
  # =========================================================================
  # Three scenarios to handle:
  # 1. Using existing launch template (var.use_existing_launch_template = true)
  #    - Use external launch_template_id + launch_template_version
  # 2. Creating new launch template (var.use_existing_launch_template = false)
  #    - Use our created launch template (aws_launch_template.envoy[0])
  #    - Works for both on-demand and spot instances
  # 3. Spot instances (var.enable_spot_instances = true)
  #    - Use mixed instances policy with our created launch template
  # =========================================================================

  use_mixed_instances_policy = var.enable_spot_instances

  # Always use a launch template (either existing or our created one)
  # This prevents the ASG module from creating its own launch template
  create_launch_template  = false
  launch_template_id      = each.value.lt_id
  launch_template_version = each.value.lt_version

  # For mixed instances policy (spot enabled)
  mixed_instances_policy = var.enable_spot_instances ? {
    instances_distribution = {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = 100 - var.spot_instance_percentage
      spot_allocation_strategy                 = var.spot_allocation_strategy
      spot_instance_pools                      = 2
      spot_max_price                           = null # Use default (on-demand price)
    }
    override = []
  } : null


  # VPC and networking
  vpc_zone_identifier = var.proxy_subnet_ids

  # Capacity
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Health check
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_cooldown          = 300

  # Target groups
  target_group_arns = each.value.target_group_arns

  # Termination and lifecycle
  termination_policies  = var.termination_policies
  max_instance_lifetime = var.max_instance_lifetime
  capacity_rebalance    = var.enable_capacity_rebalance

  # CloudWatch metrics
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  # Scaling policies - Created separately below

  # Tags
  tags = merge(local.common_tags, { Deployment = each.value.deployment })
}

# =========================================================================
# Auto Scaling Policies (Created separately)
# =========================================================================

# CPU Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  for_each = var.enable_autoscaling && var.scaling_policies.cpu_target_tracking.enabled ? local.deployments : {}

  name                   = "${local.name_prefix}-cpu-target-tracking-${each.key}"
  autoscaling_group_name = module.asg[each.key].autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scaling_policies.cpu_target_tracking.target_value
  }
}

# Memory Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "memory_target_tracking" {
  for_each = var.enable_autoscaling && var.scaling_policies.memory_target_tracking.enabled ? local.deployments : {}

  name                   = "${local.name_prefix}-memory-target-tracking-${each.key}"
  autoscaling_group_name = module.asg[each.key].autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metrics {
        id = "m1"
        metric_stat {
          metric {
            namespace   = "CWAgent"
            metric_name = "mem_used_percent"
            dimensions {
              name  = "AutoScalingGroupName"
              value = module.asg[each.key].autoscaling_group_name
            }
          }
          stat = "Average"
        }
      }
    }
    target_value = var.scaling_policies.memory_target_tracking.target_value
  }
}

