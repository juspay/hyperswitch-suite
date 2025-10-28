# =========================================================================
# SSH Key Pair for Squid Instances
# =========================================================================

# Generate RSA key pair for SSH access
resource "tls_private_key" "squid" {
  count = var.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "squid_key_pair" {
  count = var.generate_ssh_key ? 1 : 0

  key_name   = "${local.name_prefix}-keypair-${data.aws_region.current.name}"
  public_key = tls_private_key.squid[0].public_key_openssh

  tags = local.common_tags
}

# Save private key to AWS Systems Manager Parameter Store
# This allows you to retrieve the key later for SSH access if needed
resource "aws_ssm_parameter" "squid_private_key" {
  count = var.generate_ssh_key ? 1 : 0

  name        = "/ec2/keypair/${aws_key_pair.squid_key_pair[0].key_pair_id}"
  description = "Private SSH key for ${local.name_prefix} instances"
  type        = "SecureString"
  value       = tls_private_key.squid[0].private_key_pem

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-key"
    }
  )
}

# Note: Private key is saved to Parameter Store for later retrieval
# Retrieve it with:
#   aws ssm get-parameter --name "/ec2/keypair/<key-pair-id>" --with-decryption --query 'Parameter.Value' --output text > squid-keypair.pem
#   chmod 400 squid-keypair.pem
#
# Recommended: Use AWS Systems Manager Session Manager (SSM) to connect to instances instead of SSH
# If SSH is required, use the command above to retrieve the private key

# =========================================================================
# S3 Bucket for Squid Logs
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
# Upload Squid configuration files from local directory to S3 config bucket
# Only if upload_config_to_s3 is true

resource "aws_s3_object" "squid_config_files" {
  for_each = var.upload_config_to_s3 ? fileset(var.config_files_source_path, "**") : []

  bucket = var.config_bucket_name
  key    = "squid/${each.value}"
  source = "${var.config_files_source_path}/${each.value}"
  etag   = filemd5("${var.config_files_source_path}/${each.value}")

  tags = local.common_tags
}

# =========================================================================
# IAM Role for Squid Instances (Conditional - Create only if needed)
# =========================================================================
module "squid_iam_role" {
  count  = var.create_iam_role ? 1 : 0
  source = "../../base/iam-role"

  name                    = "${local.name_prefix}-role"
  description             = "IAM role for Squid proxy instances"
  service_identifiers     = ["ec2.amazonaws.com"]
  create_instance_profile = true

  # Attach AWS managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", # For SSM access
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"   # For CloudWatch metrics/logs
  ]

  # Inline policies for S3 access
  inline_policies = {
    squid-config-bucket-read = jsonencode({
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

    squid-logs-bucket-write = jsonencode({
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
  }

  tags = local.common_tags
}

# Reference to existing IAM role (if using existing)
data "aws_iam_role" "existing_squid_role" {
  count = var.create_iam_role ? 0 : 1
  name  = var.existing_iam_role_name
}

# Create a new instance profile for existing IAM role
# This allows you to reuse an existing IAM role but create a fresh instance profile
resource "aws_iam_instance_profile" "squid_profile" {
  count = !var.create_iam_role && var.create_instance_profile ? 1 : 0

  name = "${local.name_prefix}-instance-profile"
  role = data.aws_iam_role.existing_squid_role[0].name

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

# Security Group for Load Balancer (Only create if creating new NLB)
module "lb_security_group" {
  count  = var.create_nlb ? 1 : 0
  source = "../../base/security-group"

  name        = "${local.name_prefix}-lb-sg"
  description = "Security group for Squid proxy load balancer"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      description              = "Allow traffic from EKS cluster"
      from_port                = var.squid_port
      to_port                  = var.squid_port
      protocol                 = "tcp"
      source_security_group_id = var.eks_security_group_id
    }
  ]

  egress_rules = [
    {
      description = "Allow traffic to Squid ASG instances"
      from_port   = var.squid_port
      to_port     = var.squid_port
      protocol    = "tcp"
      # This will be updated after ASG SG is created
      cidr_blocks = ["0.0.0.0/0"] # Placeholder, will reference SG in real scenario
    }
  ]

  tags = local.common_tags
}

# Security Group for Squid ASG Instances
module "asg_security_group" {
  source = "../../base/security-group"

  name        = "${local.name_prefix}-asg-sg"
  description = "Security group for Squid proxy ASG instances"
  vpc_id      = var.vpc_id

  ingress_rules = [
    {
      description              = "Allow traffic from Load Balancer"
      from_port                = var.squid_port
      to_port                  = var.squid_port
      protocol                 = "tcp"
      # Use existing LB SG if provided, otherwise use the newly created one
      source_security_group_id = var.create_nlb ? module.lb_security_group[0].sg_id : var.existing_lb_security_group_id
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
# Security Group Rule: Allow Existing LB to communicate with ASG
# =========================================================================
# When using an existing NLB, add an egress rule to the existing LB's security group
# to allow traffic to the new ASG security group on squid_port
resource "aws_security_group_rule" "existing_lb_to_asg" {
  count = var.create_nlb ? 0 : 1  # Only create when using existing NLB

  type                     = "egress"
  from_port                = var.squid_port
  to_port                  = var.squid_port
  protocol                 = "tcp"
  source_security_group_id = module.asg_security_group.sg_id
  security_group_id        = var.existing_lb_security_group_id

  description = "Allow traffic from existing LB to Squid ASG instances on port ${var.squid_port}"
}

# =========================================================================
# Network Load Balancer (Conditional - Create only if needed)
# =========================================================================
module "nlb" {
  count  = var.create_nlb ? 1 : 0
  source = "../../base/nlb"

  name            = "${local.name_prefix}-nlb"
  internal        = true
  subnets         = var.lb_subnet_ids
  security_groups = [module.lb_security_group[0].sg_id]

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_cross_zone_load_balancing = true

  tags = local.common_tags
}

# =========================================================================
# Target Group (Conditional - Create only if needed)
# =========================================================================
module "target_group" {
  count  = var.create_target_group ? 1 : 0
  source = "../../base/target-group"

  name        = "${local.name_prefix}-tg"
  port        = var.squid_port
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
    port                = "traffic-port"
    protocol            = "TCP"
  }

  tags = local.common_tags
}

# =========================================================================
# Load Balancer Listener (Create only if creating new NLB)
# =========================================================================
module "nlb_listener" {
  count  = var.create_nlb ? 1 : 0
  source = "../../base/nlb-listener"

  name                = local.name_prefix
  load_balancer_arn   = module.nlb[0].nlb_arn
  port                = var.squid_port
  protocol            = "TCP"
  target_group_arn    = var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn

  tags = local.common_tags
}

# =========================================================================
# NOTE: For NLB with existing listener, we modify the existing listener's
# default action instead of creating a listener rule, since NLB listeners
# don't support rules with conditions like ALBs do.
# The target group will be attached to the ASG, and the existing listener
# should forward traffic to this target group.
# =========================================================================

# =========================================================================
# Launch Template (Conditional - Create only if not using existing)
# =========================================================================
module "launch_template" {
  count  = var.use_existing_launch_template ? 0 : 1
  source = "../../base/launch-template"

  name               = local.name_prefix
  description        = "Launch template for Squid proxy instances"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.generate_ssh_key ? aws_key_pair.squid_key_pair[0].key_name : var.key_name
  security_group_ids = [module.asg_security_group.sg_id]

  iam_instance_profile_name = local.instance_profile_name

  user_data = base64encode(local.userdata_content)

  ebs_optimized     = true
  enable_monitoring = var.enable_detailed_monitoring

  # Root volume configuration
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

  # IMDSv2 enforced (security best practice)
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
  # Even when upload_config_to_s3=false, this is safe because the resource
  # uses for_each with empty set, so Terraform just skips the dependency
  depends_on = [aws_s3_object.squid_config_files]

  name                    = "${local.name_prefix}-asg"
  launch_template_id      = local.launch_template_id
  launch_template_version = local.launch_template_version
  subnet_ids              = var.proxy_subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  target_group_arns   = [var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn]
  health_check_type   = "ELB"
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
  instance_tags = local.instance_tags
}
