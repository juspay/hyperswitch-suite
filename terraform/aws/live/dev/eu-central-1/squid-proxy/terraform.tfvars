# ============================================================================
# Development Environment - EU Central 1 - Squid Proxy Configuration
# ============================================================================
# This file contains configuration values for the dev environment
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Network Configuration
# ============================================================================
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-XXXXXXXXXXXXX"  # Replace with your VPC ID

# Subnets where Squid proxy instances will run (private subnets with NAT/IGW)
proxy_subnet_ids = [
  "subnet-XXXXXXXXXXXXX",  # Private subnet AZ1
  "subnet-XXXXXXXXXXXXX"   # Private subnet AZ2
]

# Subnets where NLB will be placed (service/public subnets)
lb_subnet_ids = [
  "subnet-XXXXXXXXXXXXX",  # Service subnet AZ1
  "subnet-XXXXXXXXXXXXX"   # Service subnet AZ2
]

# EKS Worker Node Subnet CIDRs
# IMPORTANT: NLB preserves source IP, so we need to allow traffic from EKS worker subnets
# These are the subnets where your EKS worker nodes (and pods) run
# To find these subnets:
#   aws ec2 describe-subnets --filters "Name=vpc-id,Values=YOUR_VPC_ID" \
#     --query 'Subnets[?contains(Tags[?Key==`Name`].Value|[0], `eks-worker`)].{CIDR:CidrBlock,Name:Tags[?Key==`Name`].Value|[0]}'
eks_worker_subnet_cidrs = [
  "10.0.X.0/22",   # eks-worker-nodes-one-zoneSubnet1 (AZ1) - Replace with your CIDR
  "10.0.X.0/22"    # eks-worker-nodes-one-zoneSubnet2 (AZ2) - Replace with your CIDR
]

# ============================================================================
# Squid Proxy Configuration
# ============================================================================
squid_port = 3128  # Standard Squid proxy port (don't change unless you know what you're doing)

#=======================================================================
# LAUNCH TEMPLATE CONFIGURATION
#=======================================================================
# Two options available:
#
# OPTION 1: Create New Launch Template (Current Default)
#   use_existing_launch_template = false
#   - Module creates a new launch template with specified AMI, instance type, etc.
#   - Uses ami_id, instance_type, key_name, root_volume_* below
#
# OPTION 2: Use Existing Launch Template
#   use_existing_launch_template = true
#   existing_launch_template_id = "lt-0123456789abcdef0"
#   existing_launch_template_version = "$Latest"
#   - Use this if you have a pre-configured launch template
#   - The following variables will be IGNORED (taken from launch template):
#     ❌ ami_id
#     ❌ instance_type
#     ❌ key_name (if specified in launch template)
#     ❌ root_volume_size (if specified in launch template)
#     ❌ root_volume_type (if specified in launch template)
#
# Version Options:
#   - "$Latest" = Always use the latest version (auto-updates)
#   - "$Default" = Use the default version (manually set in AWS)
#   - "1", "2", etc. = Pin to specific version number
#=======================================================================

use_existing_launch_template = false  # Set to true to use existing launch template

# Only used when use_existing_launch_template = true
# existing_launch_template_id = "lt-0123456789abcdef0"  # Replace with your launch template ID
# existing_launch_template_version = "$Latest"  # or "$Default" or "1", "2", etc.

#=======================================================================
# EC2 Configuration (ignored if use_existing_launch_template = true)
#=======================================================================
# TODO: Replace with your actual AMI ID (Amazon Linux 2 or Ubuntu)
ami_id        = "ami-XXXXXXXXXXXXXXXXX"  # Replace with your Squid AMI ID
instance_type = "t3.small"                # Smaller instance for dev

#=======================================================================

# Auto Scaling Configuration
min_size         = 1
max_size         = 2
desired_capacity = 1

# S3 Logs Bucket Configuration
# Create a new S3 bucket for logs (dev environment)
create_logs_bucket = true  # Automatically creates bucket: dev-hyperswitch-squid-logs-<account-id>-eu-central-1

# NOTE: If using existing logs bucket, set create_logs_bucket = false and provide:
# logs_bucket_name = "app-proxy-logs-225681119357-eu-central-1"
# logs_bucket_arn  = "arn:aws:s3:::app-proxy-logs-225681119357-eu-central-1"

# S3 Config Bucket Configuration
# Create a new S3 bucket for configuration files (dev environment)
create_config_bucket = true  # Automatically creates bucket: dev-hyperswitch-squid-config-<account-id>-eu-central-1

# NOTE: If using existing config bucket, set create_config_bucket = false and provide:
# config_bucket_name = "app-proxy-config-225681119357-eu-central-1"
# config_bucket_arn  = "arn:aws:s3:::app-proxy-config-225681119357-eu-central-1"

# Monitoring
enable_detailed_monitoring = false

# ============================================================================
# Storage Configuration (ignored if use_existing_launch_template = true)
# ============================================================================
# Configure root volume explicitly vs using AMI defaults
#
# Option 1: Explicit Storage Config (RECOMMENDED)
#   configure_root_volume = true
#   - Ensures consistent volume size across all instances
#   - Uses gp3 (20% cheaper, better performance than gp2)
#   - Guarantees encryption
#   - Cost: ~$1.76/month per instance (20GB gp3)
#
# Option 2: Use AMI Defaults (NOT RECOMMENDED)
#   configure_root_volume = false
#   - Uses whatever volume config is in the AMI
#   - No control over size, type, or encryption
#   - Might be too small for logs (typical AMI = 8GB)
#   - Cost savings: ~$0.70/month per instance
#   - Risk: Disk full errors, inconsistent config
#
# Bottom line: $0.88/month extra is worth the peace of mind!
# ============================================================================

configure_root_volume = true  # Recommended: Keep this enabled!
root_volume_size = 20         # GB - Enough for OS + Squid + logs
root_volume_type = "gp3"      # Latest generation (cheaper + faster than gp2)

#=======================================================================
# LOAD BALANCER CONFIGURATION
#=======================================================================
# Two modes available:
#
# MODE 1: Create New NLB
#   create_nlb = true
#   - Module creates a new Network Load Balancer with listener and target group
#   - eks_security_group_id is required for LB security group
#   - Comment out the existing_lb_name below
#
# MODE 2: Use Existing NLB (Current Setting)
#   create_nlb = false
#   - Module creates only target group and attaches to ASG
#   - Provide existing_lb_name below
#   - After apply, manually update existing NLB listener to forward to new target group
#=======================================================================

create_nlb       = true  # Set to true to create new NLB instead

# Only needed when create_nlb = false (Mode 2)
# existing_lb_name = "squid-nlb"  # Comment out if create_nlb = true

# Note for Mode 2: After terraform apply, manually update the existing NLB listener's
# default action to forward traffic to the target group ARN (check terraform outputs)

#=======================================================================
# SSH KEY CONFIGURATION
#=======================================================================
# Two options available:
#
# OPTION 1: Auto-generate new SSH key (Current Setting) - RECOMMENDED
#   generate_ssh_key = true
#   - Terraform creates EC2 key pair automatically
#   - Private key saved to AWS Systems Manager Parameter Store (SecureString)
#   - Use AWS Systems Manager Session Manager to access instances (no SSH key needed)
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
# key_name = "hyperswitch-squid-proxy-keypair-eu-central-1"

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
#       --output text > squid-keypair.pem
#     chmod 400 squid-keypair.pem
#     ssh -i squid-keypair.pem ubuntu@<instance-ip>
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

# How it works:
# 1. Config files in ./config/ directory (squid.conf, whitelist.txt, etc.)
# 2. When you run terraform apply, configs are uploaded to S3
# 3. Changes to config files trigger automatic re-upload
# 4. Userdata script downloads them during instance initialization
# 5. Git is the source of truth for all configuration files

#=======================================================================

#=======================================================================
# IAM ROLE CONFIGURATION
#=======================================================================
# Three options available:
#
# OPTION 1: Create New IAM Role + Instance Profile (Current Setting) - RECOMMENDED
#   create_iam_role = true
#   - Terraform creates a new IAM role with required permissions
#   - Includes S3 access for configs/logs, SSM, CloudWatch
#   - Automatically creates instance profile
#
# OPTION 2: Use Existing IAM Role + Create New Instance Profile - RECOMMENDED for reusing roles
#   create_iam_role = false
#   create_instance_profile = true
#   existing_iam_role_name = "my-existing-role"
#   - Reuses an existing IAM role (with permissions already configured)
#   - Creates a NEW instance profile for this deployment's launch template
#   - Best for: Sharing IAM roles across deployments while keeping launch templates separate
#
# OPTION 3: Use Existing IAM Role + Existing Instance Profile
#   create_iam_role = false
#   create_instance_profile = false
#   existing_iam_role_name = "my-existing-role"
#   existing_iam_instance_profile_name = "my-existing-instance-profile"
#   - Uses both existing IAM role and instance profile
#   - ⚠️ Warning: Instance profile can only be used by ONE launch template
#   - Required permissions: S3 (config/logs buckets), SSM, CloudWatch
#=======================================================================

create_iam_role = true  # Set to false to use existing IAM role

# Only used when create_iam_role = false
# existing_iam_role_name = "hyperswitch-squid-role"

# Only used when create_iam_role = false
create_instance_profile = true  # Set to false to use existing instance profile

# Only used when create_iam_role = false AND create_instance_profile = false
# existing_iam_instance_profile_name = "my-squid-instance-profile"

#=======================================================================
# Instance Refresh Configuration
#=======================================================================
# When enabled, ASG automatically replaces instances when launch template changes
# Provides manual checkpoints for validation during rollout
#
# How it works:
# 1. Terraform updates launch template
# 2. ASG automatically starts instance refresh
# 3. Replaces instances gradually with new launch template
# 4. Pauses at 50% for 5 minutes (checkpoint) - you can validate
# 5. If issues found, cancel with: aws autoscaling cancel-instance-refresh
# 6. If healthy, auto-continues after 5 minutes
#
# Settings explained:
# - min_healthy_percentage: Keep at least 50% of instances healthy during refresh
# - instance_warmup: Wait 5 minutes for new instances to pass health checks
# - checkpoint_percentages: [50] = Pause when 50% of instances are replaced
# - checkpoint_delay: 300 seconds (5 min) = How long to wait at checkpoint
#
# To monitor refresh:
#   aws autoscaling describe-instance-refreshes --auto-scaling-group-name dev-hyperswitch-squid-asg
#
# To cancel refresh (if issues detected):
#   aws autoscaling cancel-instance-refresh --auto-scaling-group-name dev-hyperswitch-squid-asg
#=======================================================================

enable_instance_refresh = true  # Enable automatic instance refresh on launch template changes

instance_refresh_preferences = {
  min_healthy_percentage       = 50      # Keep 50% instances healthy during refresh
  instance_warmup              = 300     # Wait 5 min for new instances to stabilize
  max_healthy_percentage       = 100     # Don't exceed desired capacity during refresh
  checkpoint_percentages       = [50]    # Pause at 50% complete for validation
  checkpoint_delay             = 300     # Wait 5 min at checkpoint before auto-continuing
  scale_in_protected_instances = "Ignore"
  standby_instances            = "Ignore"
}

# Note: launch_template changes automatically trigger refresh, no need to specify
# instance_refresh_triggers = []  # Empty by default - launch_template triggers are automatic

#=======================================================================

# ============================================================================
# NLB LISTENER CONFIGURATION (TCP and TLS)
# ============================================================================
# Configure which listeners to enable on the Network Load Balancer
#
# TCP Listener (Port 80):
#   - Unencrypted HTTP proxy traffic
#   - Simple, no certificate needed
#   - Good for testing or internal traffic
#
# TLS Listener (Port 443):
#   - Encrypted HTTPS proxy traffic
#   - Requires ACM certificate
#   - Recommended for production
#   - TLS termination at NLB (not mTLS)
#
# You can enable both listeners simultaneously!
# ============================================================================

# TCP Listener (Port 80) - Enabled by default
enable_tcp_listener = true
tcp_listener_port   = 80

# TLS Listener (Port 443) - Disabled by default
# To enable TLS:
#   1. Request ACM certificate (see below)
#   2. Set enable_tls_listener = true
#   3. Add certificate ARN to tls_certificate_arn
enable_tls_listener = false
tls_listener_port   = 443

# ACM Certificate ARN (required if enable_tls_listener = true)
# How to get certificate:
#   1. Request certificate in ACM:
#      aws acm request-certificate \
#        --domain-name "utils.outbound-dev.eu.juspay.net" \
#        --validation-method DNS \
#        --region eu-central-1
#
#   2. Validate via DNS (add CNAME record from ACM to your DNS)
#
#   3. Wait for status "ISSUED" (check with: aws acm describe-certificate)
#
#   4. Copy certificate ARN here:
# tls_certificate_arn = "arn:aws:acm:eu-central-1:ACCOUNT_ID:certificate/CERT_ID"

# SSL Policy for TLS Listener
# ELBSecurityPolicy-TLS13-1-2-2021-06 = TLS 1.3 + TLS 1.2 (recommended)
# See: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/create-tls-listener.html#describe-ssl-policies
tls_ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

# ALPN Policy (Application-Layer Protocol Negotiation)
# "None" = Standard (recommended for proxy)
# "HTTP2Preferred" = Prefer HTTP/2
# "HTTP2Only" = Require HTTP/2
tls_alpn_policy = "None"

# ============================================================================
# After enabling TLS, configure EKS pods with:
# ============================================================================
# env:
#   - name: HTTP_PROXY
#     value: "http://dev-hyperswitch-squid-nlb-XXXXX.elb.eu-central-1.amazonaws.com:80"
#   - name: HTTPS_PROXY
#     value: "https://dev-hyperswitch-squid-nlb-XXXXX.elb.eu-central-1.amazonaws.com:443"
#   - name: NO_PROXY
#     value: "localhost,127.0.0.1,.cluster.local,.svc,10.0.0.0/8,169.254.169.254"
#
# The NLB DNS name will be in terraform outputs: `terraform output proxy_endpoints`
# ============================================================================

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
