# ============================================================================
# Squid Proxy Deployment - Dev Environment
# ============================================================================
# This configuration supports TWO modes:
#
# MODE 1: Create New NLB (Default)
#   - Set create_nlb = true (or comment out the existing LB configuration)
#   - Module creates: NLB + Listener + Target Group + ASG + Security Groups
#   - Use this for: New deployments, isolated environments
#
# MODE 2: Use Existing NLB (Current Configuration)
#   - Set create_nlb = false
#   - Provide: existing_lb_name, existing_lb_arn, existing_lb_listener_arn
#   - Module creates: Target Group + ASG + ASG Security Group only
#   - Use this for: Sharing NLB across multiple services, cost optimization
#
# To switch modes:
#   - For Mode 1: Set create_nlb = true and comment out data sources below
#   - For Mode 2: Set create_nlb = false and uncomment data sources below
# ============================================================================

provider "aws" {
  region = var.region
}

# ============================================================================
# DATA SOURCES - Only needed when using EXISTING NLB (Mode 2)
# Comment these out if creating a new NLB (Mode 1)
# ============================================================================

# Reference your existing load balancer by name
data "aws_lb" "existing" {
  count = var.create_nlb ? 0 : 1  # Only fetch if using existing NLB
  name  = var.existing_lb_name
}

# Reference existing listener on the load balancer
data "aws_lb_listener" "existing" {
  count             = var.create_nlb ? 0 : 1  # Only fetch if using existing NLB
  load_balancer_arn = data.aws_lb.existing[0].arn
  port              = var.squid_port
}

# Squid Proxy Module - Using Existing LB
module "squid_proxy" {
  source = "../../../../modules/composition/squid-proxy"

  environment  = var.environment
  project_name = var.project_name

  # Network configuration
  vpc_id           = var.vpc_id
  proxy_subnet_ids = var.proxy_subnet_ids
  lb_subnet_ids    = var.lb_subnet_ids

  # Squid configuration
  squid_port      = var.squid_port
  ami_id          = var.ami_id
  instance_type   = var.instance_type

  # SSH Key Configuration
  generate_ssh_key = var.generate_ssh_key
  key_name         = var.key_name  # Only used if generate_ssh_key=false

  # Userdata with templating ({{config_bucket}} and {{logs_bucket}} will be replaced)
  custom_userdata = file("${path.module}/templates/userdata.sh")

  # S3 Logs Bucket - create or use existing
  create_logs_bucket = var.create_logs_bucket
  logs_bucket_name   = var.logs_bucket_name
  logs_bucket_arn    = var.logs_bucket_arn

  # S3 Config Bucket - create or use existing
  create_config_bucket = var.create_config_bucket
  config_bucket_name   = var.config_bucket_name
  config_bucket_arn    = var.config_bucket_arn
  s3_config_path_prefix = var.s3_config_path_prefix

  # S3 Config Upload (optional)
  upload_config_to_s3      = var.upload_config_to_s3
  config_files_source_path = "${path.module}/config"

  # ASG configuration
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Monitoring & Storage
  enable_detailed_monitoring = var.enable_detailed_monitoring
  configure_root_volume      = var.configure_root_volume
  root_volume_size           = var.root_volume_size
  root_volume_type           = var.root_volume_type

  # ========================================
  # LOAD BALANCER CONFIGURATION
  # ========================================
  # MODE 1: Create New NLB
  #   create_nlb = true
  #
  # MODE 2: Use Existing NLB
  #   create_nlb = false
  #   existing_lb_arn, existing_lb_listener_arn required
  # ========================================

  create_nlb = var.create_nlb  # Set in terraform.tfvars

  # Only used when create_nlb = false (Mode 2)
  existing_lb_arn          = var.create_nlb ? null : data.aws_lb.existing[0].arn
  existing_lb_listener_arn = var.create_nlb ? null : data.aws_lb_listener.existing[0].arn

  # NOTE: When using existing NLB (create_nlb = false):
  # After terraform apply, manually update the existing NLB listener's default
  # action to forward to the newly created target group ARN (see outputs)

  # NLB Listener Configuration (TCP and TLS)
  enable_tcp_listener  = var.enable_tcp_listener
  tcp_listener_port    = var.tcp_listener_port
  enable_tls_listener  = var.enable_tls_listener
  tls_listener_port    = var.tls_listener_port
  tls_certificate_arn  = var.tls_certificate_arn
  tls_ssl_policy       = var.tls_ssl_policy
  tls_alpn_policy      = var.tls_alpn_policy

  # Instance Refresh Configuration
  enable_instance_refresh      = var.enable_instance_refresh
  instance_refresh_preferences = var.instance_refresh_preferences
  instance_refresh_triggers    = var.instance_refresh_triggers

  # Auto Scaling Policies
  enable_autoscaling = var.enable_autoscaling
  scaling_policies   = var.scaling_policies

  tags = var.common_tags
}
