# Integration Environment - EU Central 1 - Squid Proxy
# This file contains actual values for the integration environment

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

# EC2 Configuration
# TODO: Replace with your actual AMI ID (Squid pre-installed)
ami_id        = "ami-0c55b159cbfafe1f0" # Replace with Squid AMI ID
instance_type = "t3.medium"              # Medium instance for integ
key_name      = null                     # Optional: Add your SSH key name

# Auto Scaling Configuration (Higher for integ testing)
min_size         = 1
max_size         = 3
desired_capacity = 2

# S3 Configuration
# TODO: Create this bucket first or reference existing one
config_bucket_name = "hyperswitch-integ-proxy-config-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::hyperswitch-integ-proxy-config-eu-central-1"

# Monitoring (Enabled for integ)
enable_detailed_monitoring = true

# Storage
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
# existing_lb_name = "my-existing-nlb"  # Uncomment and set if create_nlb = false

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
# key_name = "my-existing-keypair"

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
# 1. Place squid.conf, whitelist.txt, and other configs in ./config/ directory
# 2. Set upload_config_to_s3 = true
# 3. Run terraform apply - configs will be uploaded to S3 automatically
# 4. Userdata script will download them during instance initialization

#=======================================================================

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
# existing_iam_role_name = "my-squid-iam-role"
# existing_iam_instance_profile_name = "my-squid-instance-profile"

#=======================================================================

# Tags
common_tags = {
  Environment = "integration"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Team        = "platform"
  CostCenter  = "engineering"
  Region      = "eu-central-1"
}
