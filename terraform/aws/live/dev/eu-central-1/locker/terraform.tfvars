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

# OPTION 1: Use existing private subnet for locker instance
locker_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID

# OPTION 2: Create a new subnet (comment out locker_subnet_id above and uncomment below)
# create_subnet            = true
# subnet_cidr_block        = "10.0.10.0/24"  # Replace with desired CIDR block
# subnet_availability_zone = "eu-central-1a"  # Optional: specify AZ, otherwise uses first available

# ============================================================================
# Instance Configuration
# ============================================================================
# Locker AMI - should be custom AMI with locker application pre-installed
ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your locker AMI ID

# Instance type - t3.medium recommended for locker workloads
# Upgrade to t3.large or c5.large for production workloads
instance_type = "t3.medium"

# OPTION 1: Use existing SSH key pair (default)
key_name = "your-key-pair-name"  # Replace with your SSH key pair name

# OPTION 2: Create a new SSH key pair (comment out key_name above and uncomment below)
# create_key_pair = true
# public_key      = "ssh-rsa AAAAB3NzaC1yc2E..."  # Optional: provide public key, or leave commented to auto-generate
# key_name        = "custom-key-name"             # Optional: specify custom name, otherwise auto-generated
# NOTE: If public_key is not provided, a new key pair will be auto-generated and the private key
#       will be securely stored in SSM Parameter Store at: /{environment}/{project}/locker/ssh-private-key

# ============================================================================
# Security Group Rules Configuration
# ============================================================================
# Ingress rules for locker instance security group
# Note: Traffic from NLB (port 8080) is automatically configured
locker_ingress_rules = [
  # SSH access from jump host
  {
    description = "SSH access from jump host"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with jump host security group ID
  },
  # Example: Vector metrics endpoint from EKS monitoring (uncomment if needed)
  # {
  #   description = "Vector metrics scraping"
  #   from_port   = 9273
  #   to_port     = 9273
  #   protocol    = "tcp"
  #   sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with monitoring security group ID
  # },
]

# Egress rules for locker instance security group
locker_egress_rules = [
  # HTTPS for ECR, S3, AWS services
  {
    description = "HTTPS access for ECR, S3, and AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  # HTTP for package downloads
  {
    description = "HTTP access for package downloads"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  # PostgreSQL access to RDS
  {
    description = "PostgreSQL access to RDS database"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with RDS security group ID
  },
  # Example: Redis access (uncomment if needed)
  # {
  #   description = "Redis access"
  #   from_port   = 6379
  #   to_port     = 6379
  #   protocol    = "tcp"
  #   sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with Redis security group ID
  # },
]

# Ingress rules for NLB security group
nlb_ingress_rules = [
  # HTTPS access from jump host
  {
    description = "HTTPS access from jump host"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    sg_id       = ["sg-xxxxxxxxxxxxxxxxx"]  # Replace with jump host security group ID
  },
  # Example: HTTPS from specific CIDR (uncomment if needed)
  # {
  #   description = "HTTPS from internal network"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr        = ["10.0.0.0/16"]  # Replace with your CIDR
  # },
]

# Egress rules for NLB security group
# Note: Traffic to locker instance (port 8080) is automatically configured
nlb_egress_rules = [
  # Add additional egress rules here if needed
  # Example: All outbound traffic (uncomment if needed)
  # {
  #   description = "Allow all outbound traffic"
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr        = ["0.0.0.0/0"]
  # },
]

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
