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
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID

# Public subnet for external jump host (must have internet gateway)
public_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your public(management) subnet ID

# Private subnet for internal jump host
private_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private(Utils) subnet ID

# ============================================================================
# Instance Configuration
# ============================================================================
# Leave ami_ids as null to automatically use latest Amazon Linux 2 AMI
# External Jump Host AMI (public subnet)
external_jump_ami_id = "ami-xxxxxxxxxxxxxxxxx"

# Internal Jump Host AMI (private subnet)
internal_jump_ami_id = "ami-xxxxxxxxxxxxxxxxx"

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
# SSM Session Manager Configuration
# ============================================================================
# Enable SSM Session Manager access for internal jump host
# Set to true to allow direct SSM access to internal jump host
enable_internal_jump_ssm = false

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

# ============================================================================
# Security Group Rules Configuration
# ============================================================================
# Configure security group rules for jump hosts
# Default rules (always applied):
#   - External Jump: SSH to internal jump (22), HTTPS (443), HTTP (80) egress
#   - Internal Jump: SSH ingress from external jump (22)
# Additional rules below are environment-specific

# ----------------------------------------------------------------------------
# External Jump Host - Ingress Rules
# ----------------------------------------------------------------------------
# Allow access from VPN IPs or specific CIDR blocks
# Example: CIDR-based ingress rule
# external_jump_ingress_rules = [
#   {
#     description = "VPN/Office IP - SSH/SSM access"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr        = ["x.x.x.x/32"]  # Replace with your VPN/office IP
#   }
# ]

# ----------------------------------------------------------------------------
# External Jump Host - Egress Rules
# ----------------------------------------------------------------------------
# Allow external jump to access additional services (beyond defaults)
# Examples: Security group-based and CIDR-based egress rules
external_jump_egress_rules = [
  {
    description = "SSH to application servers"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with target security group ID
  },
  {
    description = "Monitoring system access"
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr        = ["10.0.0.0/16"]  # Replace with your VPC CIDR or monitoring subnet
  }
]

# ----------------------------------------------------------------------------
# Internal Jump Host - Egress Rules
# ----------------------------------------------------------------------------
# Allow internal jump to access backend services (databases, caches, etc.)
# Examples: Security group, CIDR, and prefix list-based egress rules
internal_jump_egress_rules = [
  {
    description = "Database access (PostgreSQL/MySQL)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with database security group ID
  },
  {
    description = "S3 VPC endpoint access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = ["pl-xxxxxxxx"]  # Replace with S3 prefix list for your region
  },
  {
    description = "HTTP/HTTPS to VPC CIDR on custom ports"
    from_port   = 1514
    to_port     = 1514
    protocol    = "tcp"
    cidr        = ["10.X.X.0/16"]  # Replace with your VPC CIDR
  }
]

