# ============================================================================
# Development Environment - EU Central 1 - Locker Configuration
# ============================================================================
# This file contains configuration values for the locker card vault deployment
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
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID

# Private subnet for locker instance (must have NAT gateway for outbound access)
locker_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID

# RDS CIDR block for database access
# Format: x.x.x.x/32 for single IP or x.x.x.x/24 for subnet range
rds_cidr = "10.0.0.0/24"  # Replace with your RDS subnet CIDR

# ============================================================================
# Instance Configuration
# ============================================================================
# Locker AMI - should be custom AMI with locker application pre-installed
ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your locker AMI ID

# Instance type - t3.medium recommended for locker workloads
# Upgrade to t3.large or c5.large for production workloads
instance_type = "t3.medium"

# SSH key pair name for emergency access via jump host
key_name = "your-key-pair-name"  # Replace with your SSH key pair name

# ============================================================================
# Security Configuration
# ============================================================================
# Jump host security group ID for SSH access to locker
jump_host_security_group_id = "sg-xxxxxxxxxxxxxxxxx"  # Replace with jump host security group ID

# ============================================================================
# Logging Configuration
# ============================================================================
# CloudWatch log retention in days (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)
log_retention_days = 30

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "locker"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
