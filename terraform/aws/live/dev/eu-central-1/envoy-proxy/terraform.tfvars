# Development Environment - EU Central 1 - Envoy Proxy

environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# Network Configuration
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID
proxy_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",  # Private subnet AZ1
  "subnet-yyyyyyyyyyyyyyyyy",  # Private subnet AZ2
  "subnet-zzzzzzzzzzzzzzzzz"   # Private subnet AZ3
]
lb_subnet_ids = [
  "subnet-aaaaaaaaaaaaaaa",  # Public subnet AZ1
  "subnet-bbbbbbbbbbbbbbb",  # Public subnet AZ2
  "subnet-ccccccccccccccc"   # Public subnet AZ3
]

# NOTE: EKS Security Group ID is NOT needed for Envoy proxy
# Traffic flow: CloudFront → External ALB → Envoy ASG → Internal ALB → EKS

# ============================================================================
# Security Group Rules (Environment Specific)
# ============================================================================
# Define environment-specific ingress and egress rules for ASG and External LB
#
# Each rule must have EXACTLY ONE of: 'cidr', 'ipv6_cidr', or 'sg_id':
#   - cidr: list(string) for IPv4 CIDR blocks (e.g., ["10.0.0.0/16"] or ["0.0.0.0/0"])
#   - ipv6_cidr: list(string) for IPv6 CIDR blocks (e.g., ["::/0"])
#   - sg_id: list(string) for Security Group IDs (e.g., ["sg-xxxxx"])
#
# Note: The 'type' field is automatically set by the composition layer
# (ingress_rules → type="ingress", egress_rules → type="egress")
#
# ============================================================================
# IMPORTANT: Dynamic Security Group References
# ============================================================================
# When create_lb = true (creating new ALB), the ALB security group is created
# dynamically. You can reference it using: module.envoy_proxy.alb_security_group_id
#
# However, on FIRST terraform apply, this output doesn't exist yet. So:
#
# OPTION 1: Two-step apply (Recommended for new deployments)
#   Step 1: terraform apply (creates ALB with its security group)
#   Step 2: Update ingress_rules to reference module.envoy_proxy.alb_security_group_id
#   Step 3: terraform apply (adds ASG ingress rules from ALB SG)
#
# OPTION 2: Use existing ALB (create_lb = false)
#   - Set create_lb = false
#   - Provide existing_lb_arn and existing_lb_security_group_id
#   - Reference existing_lb_security_group_id in ingress_rules
#
# OPTION 3: Temporary SG IDs (Current configuration)
#   - Use temporary security group IDs for testing
#   - Replace with actual SG IDs after first apply
#
# ============================================================================

# ============================================================================
# ASG INGRESS RULES
# ============================================================================
# Note: For dynamically created ALB security group, use:
#   sg_id = [module.envoy_proxy.alb_security_group_id]
# This will be available after first terraform apply when create_lb = true

ingress_rules = [
  # Example: SSH access from jumpbox/bastion
  {
    description = "Allow SSH from jumpbox"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxx"]  # Replace with your jumpbox security group ID
  },
  # Example: Prometheus metrics scraping
  {
    description = "Allow Prometheus metrics scraping"
    from_port   = 9901
    to_port     = 9901
    protocol    = "tcp"
    sg_id       = ["sg-yyyyyyyyyyyyyyy"]  # Replace with your monitoring SG ID
  },
  # Add more ingress rules as needed for your environment
]

# ============================================================================
# ASG EGRESS RULES
# ============================================================================
# All egress rules including DNS, S3, and application traffic
# These rules are environment-specific and fully customizable

egress_rules = [
  # -------------------------------------------------------------------------
  # DNS Resolution (Required)
  # -------------------------------------------------------------------------
  {
    description = "Allow DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr        = ["0.0.0.0/0"]
  },
  {
    description = "Allow DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },

  # -------------------------------------------------------------------------
  # S3 Access (Required for config/logs)
  # -------------------------------------------------------------------------
  # Option 1: Via VPC Endpoint (Recommended - uncomment and set prefix list ID)
  # {
  #   description     = "Allow HTTPS to S3 via VPC Gateway Endpoint"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   prefix_list_ids = ["pl-6xxxxxxx7"]  # S3 prefix list for eu-central-1
  # },

  # Option 2: Via Internet (Current - fallback)
  {
    description = "Allow HTTPS to S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },

  # -------------------------------------------------------------------------
  # Upstream Traffic (Application-Specific)
  # -------------------------------------------------------------------------
  # Traffic to Istio Internal LB / EKS
  {
    description = "Allow traffic to Istio Internal LB"
    from_port   = 80  # var.envoy_upstream_port - adjust as needed
    to_port     = 80
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]  # Will be restricted by destination ALB SG
  },

  # HTTP to Internal ALB (EKS)
  {
    description = "Allow HTTP to Internal ALB (EKS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxxx"]  # k8s-elb (Internal ALB SG) - temp for testing
  },

  # -------------------------------------------------------------------------
  # Environment-Specific Services
  # -------------------------------------------------------------------------
  # Custom TCP 5000 to Beacon service
  {
    description = "Allow traffic to Beacon service"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # beacon-sg - temp for testing
  },
]

# ============================================================================
# EXTERNAL LOAD BALANCER SECURITY GROUP RULES
# ============================================================================
# Ingress/egress rules for the external ALB security group
# Only used when create_lb = true (creating new ALB)
#
# All rules are defined here for full control per environment.

lb_ingress_rules = [
  # Example: HTTP from anywhere (IPv4)
  {
    description = "Allow HTTP from anywhere (IPv4)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  # Example: HTTPS from anywhere (IPv4)
  {
    description = "Allow HTTPS from anywhere (IPv4)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  # Example: IPv6 support (optional - uncomment if needed)
  # {
  #   description = "Allow HTTP from anywhere (IPv6)"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   ipv6_cidr   = ["::/0"]
  # },
  # Add more ALB ingress rules as needed for your environment
]

lb_egress_rules = [
  # Example: Traffic to backend service
  {
    description = "Allow traffic to backend service"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxx"]  # Replace with your backend service SG ID
  },
  # Note: Traffic to Envoy ASG on envoy_traffic_port is automatically handled
  # by the composition layer (creates egress rule to ASG security group dynamically)
]

# ============================================================================
# Envoy Port Configuration
# ============================================================================

# Traffic flow: CloudFront → External ALB:80 → Envoy:80 → Internal ALB:80 → EKS

envoy_traffic_port      = 443  # Target group port - ALB forwards traffic to this port on Envoy instances
envoy_health_check_port = 443  # Health check port - ALB sends GET /healthz requests to this port 

#=======================================================================
# LAUNCH TEMPLATE CONFIGURATION
#=======================================================================
# This module supports THREE flexible scenarios:
#
# ┌─────────────────────────────────────────────────────────────────────┐
# │ SCENARIO 1: Create New Launch Template (Current Default)           │
# ├─────────────────────────────────────────────────────────────────────┤
# │ use_existing_launch_template = false                                │
# │ enable_spot_instances = false                                       │
# │                                                                     │
# │  Module creates launch template from ami_id, instance_type, etc. │
# │  Best for: Standard on-demand deployments                        │
# │  Uses: All configuration from terraform.tfvars                   │
# └─────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────┐
# │ SCENARIO 2: Use Existing Launch Template                           │
# ├─────────────────────────────────────────────────────────────────────┤
# │ use_existing_launch_template = true                                 │
# │ existing_launch_template_id = "lt-0123456789abcdef0"                │
# │ existing_launch_template_version = "$Latest"                        │
# │                                                                     │
# │  Best for: Pre-configured templates, compliance requirements     │
# │   The following variables are IGNORED (from launch template):    │
# │     • ami_id                                                        │
# │     • instance_type                                                 │
# │     • key_name (if specified in LT)                                 │
# │     • root_volume_size (if specified in LT)                         │
# │     • root_volume_type (if specified in LT)                         │
# │     • enable_detailed_monitoring (if specified in LT)               │
# └─────────────────────────────────────────────────────────────────────┘
#
# ┌─────────────────────────────────────────────────────────────────────┐
# │ SCENARIO 3: Spot Instances (Module Creates LT + Mixed Policy)      │
# ├─────────────────────────────────────────────────────────────────────┤
# │ use_existing_launch_template = false                                │
# │ enable_spot_instances = true                                        │
# │                                                                     │
# │  Module creates launch template with spot configuration          │
# │  Best for: Cost optimization with spot instances                 │
# │  Supports: Mix of spot and on-demand instances                   │
# └─────────────────────────────────────────────────────────────────────┘
#
# Version Options (for existing launch template):
#   - "$Latest"  = Always use the latest version (auto-updates)
#   - "$Default" = Use the default version (manually set in AWS)
#   - "1", "2"   = Pin to specific version number
#=======================================================================

use_existing_launch_template = false  # Set to true to use existing launch template

# Only used when use_existing_launch_template = true
# existing_launch_template_id = "lt-0123456789abcdef0"  # Replace with your launch template ID
# existing_launch_template_version = "$Latest"  # or "$Default" or "1", "2", etc.

#=======================================================================
# EC2 Configuration (ignored if use_existing_launch_template = true)
#=======================================================================
# TODO: Replace with your actual AMI ID
ami_id        = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Envoy AMI ID
instance_type = "t3.small"

# Auto Scaling Configuration
min_size         = 1
max_size         = 2
desired_capacity = 1

# ============================================================================
# Auto Scaling Policies (CPU and Memory-based)
# ============================================================================
# Enable auto-scaling to automatically add/remove instances based on load
# Uses AWS built-in metrics - no custom CloudWatch metrics needed
#
# How it works:
# - CPU-based: Scales when average CPU across all instances exceeds target
# - Memory-based: Scales when average memory usage exceeds target (requires CloudWatch agent)
# - Target Tracking: AWS automatically creates scale-up AND scale-down policies
# - Cooldown: Prevents rapid scaling (scale-out: 60s, scale-in: 300s by default)
#
# Example scenario with cpu_target_tracking at 70%:
# - Current: 1 instance at 85% CPU → ASG adds 1 instance
# - Result: 2 instances at ~42% CPU → Stable
# - Later: 2 instances at 20% CPU → ASG removes 1 instance after 15 min
#
# Recommendation for dev:
# - Start with CPU-based scaling only
# - Monitor behavior, then add memory-based if needed
# ============================================================================

enable_autoscaling = true  # Set to true to enable auto-scaling

scaling_policies = {
  # CPU Target Tracking - Recommended for most workloads
  cpu_target_tracking = {
    enabled      = true  # Set to true to enable
    target_value = 70.0   # Scale when average CPU > 70%
  }

  # Memory Target Tracking - Optional (requires CloudWatch agent)
  # Note: CloudWatch agent must be installed and configured on instances
  # to publish memory metrics to CloudWatch under "CWAgent" namespace
  memory_target_tracking = {
    enabled      = false  # Set to true after installing CloudWatch agent
    target_value = 70.0   # Scale when average memory > 70%
  }
}

# S3 Logs Bucket Configuration
# Create a new S3 bucket for logs (dev environment)
create_logs_bucket = true  # Automatically creates bucket: dev-hyperswitch-envoy-logs-<account-id>-eu-central-1

# NOTE: If using existing logs bucket, set create_logs_bucket = false and provide:
# logs_bucket_name = "app-proxy-logs-<account-id>-eu-central-1"
# logs_bucket_arn  = "arn:aws:s3:::app-proxy-logs-<account-id>-eu-central-1"

# S3 Config Bucket Configuration
# Create a new S3 bucket for configuration files (dev environment)
create_config_bucket = true  # Automatically creates bucket: dev-hyperswitch-envoy-config-<account-id>-eu-central-1

# NOTE: If using existing config bucket, set create_config_bucket = false and provide:
# config_bucket_name = "app-proxy-config-<account-id>-eu-central-1"
# config_bucket_arn  = "arn:aws:s3:::app-proxy-config-<account-id>-eu-central-1"

# Monitoring
enable_detailed_monitoring = false

# Storage (ignored if use_existing_launch_template = true)
root_volume_size = 20
root_volume_type = "gp3"

#=======================================================================
# SSH KEY CONFIGURATION
#=======================================================================
# Two options available:
#
# OPTION 1: Auto-generate new SSH key (Current Setting) - RECOMMENDED
#   generate_ssh_key = true
#   - Terraform creates EC2 key pair automatically
#   - Private key NOT saved locally (security best practice)
#   - Use AWS Systems Manager Session Manager to access instances
#   - SSM is already enabled via IAM role (AmazonSSMManagedInstanceCore)
#
# OPTION 2: Use existing SSH key pair
#   generate_ssh_key = false
#   key_name = "my-existing-keypair"
#   - You must already have this key pair in EC2 console
#   - You must manage the .pem file yourself
#=======================================================================

generate_ssh_key = true  # Set to false to use existing key

# Only used when generate_ssh_key = false
# key_name = "hyperswitch-envoy-proxy-keypair-eu-central-1"

#=======================================================================
# SSH ACCESS OPTIONS (when generate_ssh_key = true):
#=======================================================================
#
# OPTION A: Use SSM Session Manager (RECOMMENDED - No SSH key needed)
#   aws ssm start-session --target <instance-id>
#
# OPTION B: Retrieve SSH private key from Parameter Store
#   After terraform apply, get the Parameter Store path from outputs:
#     terraform output ssh_key_parameter_name
#
#   Then retrieve the key with:
#     aws ssm get-parameter \
#       --name "/ec2/keypair/<key-pair-id>" \
#       --with-decryption \
#       --query 'Parameter.Value' \
#       --output text > envoy-keypair.pem
#     chmod 400 envoy-keypair.pem
#     ssh -i envoy-keypair.pem ubuntu@<instance-ip>
#
#   Or use the command from terraform outputs:
#     terraform output -raw ssh_key_retrieval_command | bash
#=======================================================================

#=======================================================================
# S3 CONFIG UPLOAD
#=======================================================================
# Upload config files from ./config directory to S3
# Git is the source of truth - any changes to files will trigger re-upload
upload_config_to_s3 = true  # Automatically uploads configs from ./config directory

# Specify the main Envoy config filename (receives template substitution)
# Examples:
#   - envoy_config_filename = "envoy.yaml"       # Default
#   - envoy_config_filename = "envoy-dev.yaml"   # Dev-specific
#   - envoy_config_filename = "proxy-config.yaml" # Custom name
envoy_config_filename = "envoy.yaml"

# How it works:
# 1. Config files in ./config/ directory (envoy.yaml, etc.)
# 2. When you run terraform apply, configs are uploaded to S3
# 3. The file specified in envoy_config_filename receives template substitution
# 4. Other files are uploaded as-is (e.g., additional config files)
# 5. Changes to config files trigger automatic re-upload
# 6. Userdata script downloads them during instance initialization

#=======================================================================
# ENVOY CONFIGURATION TEMPLATING
#=======================================================================
# These values replace {{placeholders}} in config/envoy.yaml
# TODO: Replace with your actual values

hyperswitch_cloudfront_dns = "dXXXXXXXXXXXXX.cloudfront.net"  # Replace with your CloudFront distribution DNS
internal_loadbalancer_dns  = "your-internal-alb-XXXXXXXXXX.eu-central-1.elb.amazonaws.com"  # Replace with your internal ALB DNS

# Template placeholders in envoy.yaml:
# {{hyperswitch_cloudfront_dns}} - Replaced with above value
# {{internal_loadbalancer_dns}}  - Replaced with above value
# {{eks_cluster_name}}           - Replaced with "dev-hyperswitch-cluster"

#=======================================================================
# INSTANCE REFRESH (Automatic Rolling Updates)
#=======================================================================
# Enable automatic instance refresh when envoy.yaml changes
enable_instance_refresh = true

# How it works:
# 1. You update config/envoy.yaml
# 2. Run terraform apply
# 3. ASG automatically replaces instances one-by-one (zero downtime)
# 4. Keeps 50% instances healthy during update

#=======================================================================
# LOAD BALANCER CONFIGURATION
#=======================================================================
# Architecture: CloudFront → External ALB → Envoy ASG → Internal ALB → EKS
#
# Two modes available:
#
# MODE 1: Create New Application Load Balancer (Default)
#   create_lb = true
#   create_target_group = true
#   - Module creates: Public ALB + HTTP Listener (port 80) + Target Group
#   - ALB receives traffic from CloudFront
#   - Target Group points to Envoy ASG instances on port 80
#
# MODE 2: Use Existing ALB and Target Group
#   create_lb = false
#   create_target_group = false
#   existing_tg_arn = "arn:aws:elasticloadbalancing:..."
#   existing_lb_security_group_id = "sg-xxxxx"
#   - Module only creates Envoy ASG
#   - Attaches ASG to existing target group
#   - Adds egress rule to existing ALB security group
#
# Note: For production, consider adding HTTPS listener (port 443) with SSL cert
#=======================================================================

create_lb           = true  # Set to true to create new ALB
create_target_group = true  # Set to true to create new target group

# Required when using existing ALB (create_lb = false)
# TODO: Replace with your actual external ALB ARN and security group ID
# existing_lb_arn               = "arn:aws:elasticloadbalancing:eu-central-1:<account-id>:loadbalancer/app/external-lb/a30fbd9d42141361"
# existing_lb_security_group_id = "sg-04399aafbd3bb9a18"  # Security group ID (not ARN) of existing external ALB

# Optional: Only needed if create_target_group = false (currently creating new target group)
# existing_tg_arn = "arn:aws:elasticloadbalancing:eu-central-1:<account-id>:targetgroup/your-envoy-tg/xxxxx"

#=======================================================================
# IAM ROLE CONFIGURATION
#=======================================================================
# Two options available:
#
# OPTION 1: Create New IAM Role (Current Setting) - RECOMMENDED
#   create_iam_role = true
#   - Terraform creates a new IAM role with required permissions
#   - Includes S3 access for configs/logs, SSM, CloudWatch
#   - Automatically creates instance profile
#
# OPTION 2: Use Existing IAM Role
#   create_iam_role = false
#   existing_iam_role_name = "my-existing-role"
#   existing_iam_instance_profile_name = "my-existing-instance-profile"
#   - Use this if you have a pre-existing IAM role with proper permissions
#   - Required permissions: S3 (config/logs buckets), SSM, CloudWatch
#=======================================================================

create_iam_role = true  # Set to false to use existing IAM role

# Only used when create_iam_role = false
# existing_iam_role_name = "my-envoy-iam-role"
# existing_iam_instance_profile_name = "my-envoy-instance-profile"

#=======================================================================
# SSL/TLS CONFIGURATION
#=======================================================================
# Enable HTTPS listener with SSL certificate
enable_https_listener = false  # Set to true to enable HTTPS on port 443

# Required if enable_https_listener = true
# ssl_certificate_arn = "arn:aws:acm:eu-central-1:xxxxx:certificate/xxxxx"
# ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

# Enable HTTP to HTTPS redirect (requires enable_https_listener = true)
enable_http_to_https_redirect = false

#=======================================================================
# ADVANCED LISTENER RULES
#=======================================================================
# Example: Header-based routing, path-based routing
# Uncomment and modify as needed

# listener_rules = [
#   {
#     priority = 1
#     actions = [
#       {
#         type             = "forward"
#         target_group_arn = "arn:aws:elasticloadbalancing:..."  # Your target group ARN
#       }
#     ]
#     conditions = [
#       {
#         http_header = {
#           http_header_name = "x-cloudfront-secret"
#           values           = ["your-secret-value"]
#         }
#       }
#     ]
#   }
# ]

#=======================================================================
# WAF CONFIGURATION
#=======================================================================
# Enable AWS WAF for additional security
enable_waf = false

# Required if enable_waf = true
# waf_web_acl_arn = "arn:aws:wafv2:eu-central-1:xxxxx:regional/webacl/xxxxx"

#=======================================================================
# TARGET GROUP PROTOCOL
#=======================================================================
# Protocol for target group (HTTP or HTTPS)
# Use HTTPS if Envoy is configured to listen on HTTPS
target_group_protocol = "HTTP"

#=======================================================================
# S3 VPC ENDPOINT (Optional)
#=======================================================================
# Prefix list ID for S3 VPC endpoint for better security and performance
# Find with: aws ec2 describe-prefix-lists --region eu-central-1
# s3_vpc_endpoint_prefix_list_id = "pl-6ea54007"  # Example for eu-central-1

#=======================================================================
# SPOT INSTANCES CONFIGURATION
#=======================================================================
# Enable spot instances for cost savings (not recommended for production)
enable_spot_instances = false

# Spot instance configuration (only used if enable_spot_instances = true)
spot_instance_percentage = 50  # 50% spot, 50% on-demand
on_demand_base_capacity  = 1   # Always keep 1 on-demand instance
spot_allocation_strategy = "capacity-optimized"
enable_capacity_rebalance = false

#=======================================================================
# ASG ADVANCED CONFIGURATION
#=======================================================================
# Termination policies (order matters)
termination_policies = ["OldestLaunchTemplate", "OldestInstance", "Default"]

# Maximum instance lifetime in seconds (0 = no limit)
# 604800 = 7 days, useful for forcing regular instance refresh
max_instance_lifetime = 0

#=======================================================================

# Tags
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
