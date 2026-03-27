# ============================================================================
# Development Environment - EU Central 1 - Jump Host Configuration
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
vpc_id = "vpc-xxxxxxxxxxxxxxxxx" # Replace with your VPC ID

# Public subnet for jump host (must have internet gateway)
public_subnet_id = "subnet-xxxxxxxxxxxxxxxxx" # Replace with your public(management) subnet ID

# ============================================================================
# Instance Configuration
# ============================================================================
# Leave ami_id as null to automatically use latest Amazon Linux 2023 AMI
external_jump_ami_id = "ami-xxxxxxxxxxxxxxxxx"

# Instance type - t3.micro is sufficient for jump hosts (2 vCPU, 1 GB RAM)
# Upgrade to t3.small if needed (2 vCPU, 2 GB RAM)
instance_type = "t3.medium"

# Root volume configuration
root_volume_size = 20    # GB
root_volume_type = "gp3" # General Purpose SSD

# ============================================================================
# Logging Configuration
# ============================================================================
# CloudWatch log retention in days (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653)
log_retention_days = 30

# ============================================================================
# Migration Mode Configuration
# ============================================================================
# Enable SSM SendCommand permissions for Packer AMI migration (SECURITY RISK)
# This grants sudo-level access via SSM commands and should ONLY be enabled
# during active Packer migrations. Set to false after migration is complete.
#
# Permissions affected:
#   - ssm:DescribeInstanceInformation
#   - ssm:SendCommand
#   - ssm:GetCommandInvocation
#   - ssm:ListCommandInvocations
#
# Default: false (secure)
# Set to true only when running Packer migration, then immediately revert to false
enable_migration_mode = false

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}



