# Development Environment - EU Central 1 - Envoy Proxy

environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# Network Configuration
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-083eba8b4449acaac"
proxy_subnet_ids = [
  "subnet-0095f1439ed2a59fc",
  "subnet-0846e9cb642f9c7b9"
]
lb_subnet_ids = [
  "subnet-05ca7c5af3dbef091",
  "subnet-0015119340b5e7835"
]

# NOTE: EKS Security Group ID is NOT needed for Envoy proxy
# Envoy receives traffic FROM CloudFront via ALB (inbound)
# EKS does NOT initiate connections TO Envoy (no outbound from EKS to Envoy)
# Traffic flow: CloudFront → External ALB → Envoy ASG → Internal ALB → EKS
#
# This is different from Squid proxy where:
# - EKS pods make outbound requests TO Squid
# - Squid needs to allow traffic FROM EKS security group

# Envoy Configuration
envoy_admin_port    = 9901
envoy_listener_port = 10000
envoy_traffic_port      = 80
envoy_health_check_port = 80 

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
# TODO: Replace with your actual AMI ID
ami_id        = "ami-0d600a369f03fe0c7"
instance_type = "t3.small"

# Auto Scaling Configuration
min_size         = 1
max_size         = 2
desired_capacity = 1

# S3 Configuration
# TODO: Create this bucket first
config_bucket_name = "app-proxy-config-225681119357-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::app-proxy-config-225681119357-eu-central-1"

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

generate_ssh_key = false  # Set to false to use existing key

# Only used when generate_ssh_key = false
key_name = "hyperswitch-envoy-proxy-keypair-eu-central-1"

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
upload_config_to_s3 = false  # Set to true to auto-upload configs

# How to use:
# 1. Place envoy.yaml and other configs in ./config/ directory
# 2. Set upload_config_to_s3 = true
# 3. Run terraform apply - configs will be uploaded to S3 automatically
# 4. Userdata script will download them during instance initialization

#=======================================================================
# ENVOY CONFIGURATION TEMPLATING
#=======================================================================
# These values replace {{placeholders}} in config/envoy.yaml
# TODO: Replace with your actual values

hyperswitch_cloudfront_dns = ""  # e.g., "d1234567890.cloudfront.net"
internal_loadbalancer_dns  = ""  # e.g., "internal-alb-123.eu-central-1.elb.amazonaws.com"

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

create_lb           = false  # Set to true to create new ALB
create_target_group = true  # Set to true to create new target group

# Required when using existing ALB (create_lb = false)
# TODO: Replace with your actual external ALB ARN and security group ID
existing_lb_arn               = "arn:aws:elasticloadbalancing:eu-central-1:225681119357:loadbalancer/app/external-lb/a30fbd9d42141361"
existing_lb_security_group_id = "sg-04399aafbd3bb9a18"  # Security group ID (not ARN) of existing external ALB

# Optional: Only needed if create_target_group = false (currently creating new target group)
# existing_tg_arn = "arn:aws:elasticloadbalancing:eu-central-1:225681119357:targetgroup/your-envoy-tg/xxxxx"

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

# Tags
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
