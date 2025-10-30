# Integration Environment - EU Central 1 - Squid Proxy
# This file contains actual values for the integ environment

environment  = "integ"
region       = "eu-central-1"
project_name = "hyperswitch"

# Network Configuration
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-xxxxxxxxx"
proxy_subnet_ids = [
  "subnet-xxxxxxxxx", # Private subnet AZ1
  "subnet-yyyyyyyyy"  # Private subnet AZ2
]
lb_subnet_ids = [
  "subnet-zzzzzzzzz", # Service subnet AZ1
  "subnet-aaaaaaaaa"  # Service subnet AZ2
]

# EKS Configuration
# TODO: Replace with your actual EKS security group ID
eks_security_group_id = "sg-xxxxxxxxx"

# Squid Configuration
squid_port = 3128

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
ami_id        = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
instance_type = "t3.medium"             # Larger instance for integ

#=======================================================================

# Auto Scaling Configuration
min_size         = 1
max_size         = 3
desired_capacity = 2

# S3 Configuration
# TODO: Create this bucket first or reference existing one
config_bucket_name = "hyperswitch-integ-proxy-config-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::hyperswitch-integ-proxy-config-eu-central-1"

# Monitoring
enable_detailed_monitoring = true

# Storage (ignored if use_existing_launch_template = true)
root_volume_size = 30
root_volume_type = "gp3"

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

create_nlb       = true  # Set to false to use existing NLB instead

# Only needed when create_nlb = false (Mode 2)
# existing_lb_name = "squid-nlb-integ"  # Uncomment if create_nlb = false

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
upload_config_to_s3 = false  # Set to true to auto-upload configs

# How to use:
# 1. Place squid.conf and other configs in ./config/ directory
# 2. Set upload_config_to_s3 = true
# 3. Run terraform apply - configs will be uploaded to S3 automatically
# 4. Userdata script will download them during instance initialization

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
#   aws autoscaling describe-instance-refreshes --auto-scaling-group-name integ-hyperswitch-squid-asg
#
# To cancel refresh (if issues detected):
#   aws autoscaling cancel-instance-refresh --auto-scaling-group-name integ-hyperswitch-squid-asg
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

# Tags
common_tags = {
  Environment = "integration"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
