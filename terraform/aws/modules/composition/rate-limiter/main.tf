# =========================================================================
# IAM Role for Rate Limiter Instances
# =========================================================================
module "iam_role" {
  count   = var.create_iam_role ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role             = true
  create_instance_profile = true

  role_name         = "${local.name_prefix}-role"
  role_description  = "IAM role for rate limiter instances"
  role_requires_mfa = false

  trusted_role_services = ["ec2.amazonaws.com"]

  custom_role_policy_arns = var.iam_managed_policy_arns

  inline_policy_statements = concat(
    var.iam_inline_policy_statements,
    [
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
      }
    ]
  )

  tags = local.common_tags
}

# Create instance profile for existing IAM role
resource "aws_iam_instance_profile" "this" {
  count = !var.create_iam_role && var.create_instance_profile ? 1 : 0

  name = "${local.name_prefix}-instance-profile"
  role = var.iam_role_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance-profile"
    }
  )
}

# =========================================================================
# S3 Bucket for Rate Limiter Configuration
# =========================================================================
module "config_bucket" {
  count   = var.create_config_bucket ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket        = "${local.name_prefix}-config-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
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
resource "aws_s3_object" "rate_limiter_config_files" {
  for_each = var.upload_config_to_s3 ? fileset(var.config_files_source_path, "**") : []

  bucket = local.config_bucket_name
  key    = each.value
  source = "${var.config_files_source_path}/${each.value}"
  etag   = filemd5("${var.config_files_source_path}/${each.value}")

  tags = local.common_tags
}

# =========================================================================
# Security Groups
# =========================================================================

# Security Group for NLB
module "nlb_security_group" {
  count   = var.create_nlb ? 1 : 0
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-nlb-sg"
  description = "Security group for rate limiter Network Load Balancer"
  vpc_id      = var.vpc_id

  egress_rules  = []
  ingress_rules = []

  tags = local.common_tags
}

# Security Group for ASG Instances
module "asg_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-asg-sg"
  description = "Security group for rate limiter ASG instances"
  vpc_id      = var.vpc_id

  egress_rules  = []
  ingress_rules = []

  tags = local.common_tags
}

# =========================================================================
# NLB Security Group Rules
# =========================================================================

# Ingress rules for NLB
resource "aws_security_group_rule" "nlb_ingress" {
  for_each = var.create_nlb ? var.nlb_ingress_rules : {}

  security_group_id = module.nlb_security_group[0].security_group_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# Egress from NLB to ASG
resource "aws_security_group_rule" "nlb_egress_to_asg" {
  count = var.create_nlb ? 1 : 0

  security_group_id        = module.nlb_security_group[0].security_group_id
  type                     = "egress"
  from_port                = var.traffic_port
  to_port                  = var.traffic_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.security_group_id
  description              = "Allow traffic from NLB to ASG instances"
}

# =========================================================================
# ASG Security Group Rules
# =========================================================================

# Ingress from NLB to ASG
resource "aws_security_group_rule" "asg_ingress_from_nlb" {
  count = var.create_nlb ? 1 : 0

  security_group_id        = module.asg_security_group.security_group_id
  type                     = "ingress"
  from_port                = var.traffic_port
  to_port                  = var.traffic_port
  protocol                 = "tcp"
  source_security_group_id = module.nlb_security_group[0].security_group_id
  description              = "Allow traffic from NLB"
}

# Health check port ingress from NLB (if different from traffic port)
resource "aws_security_group_rule" "asg_ingress_healthcheck" {
  count = var.create_nlb && local.health_check_port != var.traffic_port ? 1 : 0

  security_group_id        = module.asg_security_group.security_group_id
  type                     = "ingress"
  from_port                = local.health_check_port
  to_port                  = local.health_check_port
  protocol                 = "tcp"
  source_security_group_id = module.nlb_security_group[0].security_group_id
  description              = "Allow health checks from NLB"
}

# Additional ingress rules for ASG
resource "aws_security_group_rule" "asg_ingress" {
  for_each = var.asg_ingress_rules

  security_group_id = module.asg_security_group.security_group_id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# Egress rules for ASG
resource "aws_security_group_rule" "asg_egress" {
  for_each = var.asg_egress_rules

  security_group_id = module.asg_security_group.security_group_id
  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

# Egress to S3 (HTTPS) via VPC Endpoint prefix list
resource "aws_security_group_rule" "asg_egress_to_s3" {
  security_group_id = module.asg_security_group.security_group_id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  description       = "Allow HTTPS outbound to S3 via VPC endpoint"
}

# Egress to ElastiCache
resource "aws_security_group_rule" "asg_egress_to_elasticache" {
  count = var.elasticache_config.enabled ? 1 : 0

  security_group_id        = module.asg_security_group.security_group_id
  type                     = "egress"
  from_port                = var.elasticache_config.port
  to_port                  = var.elasticache_config.port
  protocol                 = "tcp"
  source_security_group_id = module.elasticache[0].security_group_id
  description              = "Allow outbound traffic to ElastiCache"
}

# Ingress from rate limiter instances to ElastiCache
resource "aws_security_group_rule" "elasticache_ingress_from_asg" {
  count = var.elasticache_config.enabled && var.elasticache_config.create_security_group ? 1 : 0

  security_group_id        = module.elasticache[0].security_group_id
  type                     = "ingress"
  from_port                = var.elasticache_config.port
  to_port                  = var.elasticache_config.port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.security_group_id
  description              = "Allow inbound traffic from rate limiter instances"
}

# =========================================================================
# Network Load Balancer
# =========================================================================
resource "aws_lb" "this" {
  count = var.create_nlb ? 1 : 0

  name               = "${local.name_prefix}-nlb"
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.nlb_subnet_ids

  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_deletion_protection       = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each = var.access_logs.enabled ? [1] : []
    content {
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
      enabled = var.access_logs.enabled
    }
  }

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
resource "aws_lb_target_group" "this" {
  count = var.create_nlb ? 1 : 0

  name                 = "${local.name_prefix}-tg"
  port                 = var.traffic_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    port                = tostring(local.health_check_port)
    protocol            = var.health_check_protocol
    path                = var.health_check_protocol == "HTTP" || var.health_check_protocol == "HTTPS" ? var.health_check_path : null
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# =========================================================================
# NLB Listeners
# =========================================================================
resource "aws_lb_listener" "this" {
  for_each = var.create_nlb ? var.listeners : {}

  load_balancer_arn = aws_lb.this[0].arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.protocol == "TLS" ? each.value.certificate_arn : null
  alpn_policy       = each.value.alpn_policy
  ssl_policy        = each.value.protocol == "TLS" ? each.value.ssl_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-listener-${each.key}"
    }
  )
}

# =========================================================================
# Launch Template
# =========================================================================
resource "aws_launch_template" "this" {
  count = var.use_existing_launch_template ? 0 : 1

  name_prefix   = "${local.name_prefix}-"
  description   = "Launch template for rate limiter instances"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [module.asg_security_group.security_group_id]
  user_data              = base64encode(local.userdata_content)

  iam_instance_profile {
    name = var.create_iam_role ? module.iam_role[0].iam_instance_profile_name : var.iam_instance_profile_name
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  dynamic "metadata_options" {
    for_each = var.imds_http_endpoint != null || var.imds_http_tokens != null ? [1] : []
    content {
      http_endpoint               = var.imds_http_endpoint
      http_tokens                 = var.imds_http_tokens
      http_put_response_hop_limit = var.imds_http_put_response_hop_limit
      instance_metadata_tags      = var.imds_instance_metadata_tags
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.enable_ebs_block_device ? [1] : []
    content {
      device_name = "/dev/xvda"
      ebs {
        volume_size           = var.root_volume_size
        volume_type           = var.root_volume_type
        delete_on_termination = true
        encrypted             = var.ebs_encrypted
        kms_key_id            = var.ebs_kms_key_id
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
      Name = "${local.name_prefix}-lt"
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
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.0"

  name = "${local.name_prefix}-asg"

  create_launch_template  = false
  launch_template_id      = local.launch_template_id
  launch_template_version = local.launch_template_version

  use_mixed_instances_policy = var.enable_spot_instances

  mixed_instances_policy = var.enable_spot_instances ? {
    instances_distribution = {
      on_demand_base_capacity                  = var.on_demand_base_capacity
      on_demand_percentage_above_base_capacity = 100 - var.spot_instance_percentage
      spot_allocation_strategy                 = var.spot_allocation_strategy
      spot_instance_pools                      = 2
      spot_max_price                           = null
    }
    launch_template = {
      override = var.spot_instance_types
    }
  } : null

  vpc_zone_identifier = var.asg_subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown

  traffic_source_attachments = var.create_nlb ? {
    nlb_tg = {
      traffic_source_identifier = aws_lb_target_group.this[0].arn
      traffic_source_type       = "elbv2"
    }
  } : null

  termination_policies  = var.termination_policies
  max_instance_lifetime = var.max_instance_lifetime
  capacity_rebalance    = var.enable_capacity_rebalance

  protect_from_scale_in = var.protect_from_scale_in

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupStandbyInstances"
  ]

  tags = local.common_tags
}

# =========================================================================
# Auto Scaling Policies
# =========================================================================

# CPU Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count = var.enable_autoscaling && var.scaling_policies.cpu_target_tracking.enabled ? 1 : 0

  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = module.asg.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scaling_policies.cpu_target_tracking.target_value
  }
}

# Request Count Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "request_count_target_tracking" {
  count = var.enable_autoscaling && var.scaling_policies.request_count_target_tracking.enabled && var.create_nlb ? 1 : 0

  name                   = "${local.name_prefix}-request-count-target-tracking"
  autoscaling_group_name = module.asg.autoscaling_group_name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this[0].arn_suffix}/${aws_lb_target_group.this[0].arn_suffix}"
    }
    target_value = var.scaling_policies.request_count_target_tracking.target_value
  }
}

# =========================================================================
# CloudWatch Log Group
# =========================================================================
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/ec2/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )
}

# =========================================================================
# ElastiCache for Rate Limiter
# =========================================================================
module "elasticache" {
  source = "../elasticache"
  count  = var.elasticache_config.enabled ? 1 : 0

  environment  = var.environment
  project_name = "${var.project_name}-ratelimiter"
  vpc_id       = var.vpc_id
  subnet_ids   = var.elasticache_config.subnet_ids
  tags         = local.common_tags

  # Engine Configuration
  engine               = var.elasticache_config.engine
  engine_version       = var.elasticache_config.engine_version
  parameter_group_name = var.elasticache_config.parameter_group_name
  port                 = var.elasticache_config.port

  # Node Configuration
  node_type               = var.elasticache_config.node_type
  num_cache_clusters      = var.elasticache_config.num_cache_clusters
  num_node_groups         = var.elasticache_config.num_node_groups
  replicas_per_node_group = var.elasticache_config.replicas_per_node_group

  # Cluster Mode
  cluster_mode = var.elasticache_config.cluster_mode

  # High Availability
  automatic_failover_enabled = var.elasticache_config.automatic_failover_enabled
  multi_az_enabled           = var.elasticache_config.multi_az_enabled

  # Security
  at_rest_encryption_enabled = var.elasticache_config.at_rest_encryption_enabled
  transit_encryption_enabled = var.elasticache_config.transit_encryption_enabled
  auth_token                 = var.elasticache_config.auth_token

  # Subnet and Security Group
  create_elasticache_subnet_group = var.elasticache_config.create_subnet_group
  elasticache_subnet_group_name   = var.elasticache_config.subnet_group_name
  create_security_group           = var.elasticache_config.create_security_group
  existing_security_group_ids     = var.elasticache_config.create_security_group ? [] : var.elasticache_config.existing_security_group_ids

  # Maintenance & Backup
  maintenance_window       = var.elasticache_config.maintenance_window
  snapshot_window          = var.elasticache_config.snapshot_window
  snapshot_retention_limit = var.elasticache_config.snapshot_retention_limit
  apply_immediately        = var.elasticache_config.apply_immediately
}
