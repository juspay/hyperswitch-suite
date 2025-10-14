# Development Environment - EU Central 1 - Squid Proxy
# This file contains actual values for the dev environment

environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# Network Configuration
# TODO: Replace with your actual VPC and subnet IDs
vpc_id = "vpc-09a8"
proxy_subnet_ids = [
  "subnet-0b35", # Private subnet AZ1
  "subnet-0a30"  # Private subnet AZ2
]
lb_subnet_ids = [
  "subnet-0392", # Service subnet AZ1
  "subnet-01a9"  # Service subnet AZ2
]

# EKS Configuration
# TODO: Replace with your actual EKS security group ID
eks_security_group_id = "sg-06e7"

# Squid Configuration
squid_port = 3128

# EC2 Configuration
# TODO: Replace with your actual AMI ID (Amazon Linux 2 or Ubuntu)
ami_id        = "ami-08d" # squid ami id 
instance_type = "t3.small"               # Smaller instance for dev
key_name      = null                     # Optional: Add your SSH key name

# Auto Scaling Configuration
min_size         = 1
max_size         = 2
desired_capacity = 1

# S3 Configuration
# TODO: Create this bucket first or reference existing one
config_bucket_name = "hyperswitch-dev-proxy-config-eu-central-1"
config_bucket_arn  = "arn:aws:s3:::hyperswitch-dev-proxy-config-eu-central-1"

# Monitoring
enable_detailed_monitoring = false

# Storage
root_volume_size = 20
root_volume_type = "gp3"

#=======================================================================
# EXISTING LOAD BALANCER CONFIGURATION
#=======================================================================

create_nlb       = false 

# Option 1: Use LB name
existing_lb_name = "squid-nlb"

# Option 2: Use LB ARN (more reliable)
# existing_lb_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/net/my-nlb/abc123"

# Listener port (must match your existing listener)
# squid_port = 3128  # Already defined above

# Note: After terraform apply, you'll need to manually update the existing
# NLB listener's default action to forward traffic to the target group
# created by this module. The target group ARN will be in the outputs.

#=======================================================================

# Tags
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
