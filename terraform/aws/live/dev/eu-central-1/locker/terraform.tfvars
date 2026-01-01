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

# Number of instances to create (default: 1)
# Increase for high availability and load distribution
# instance_count = 1  # Uncomment and modify to create multiple instances

# Locker service port (default: 8080)
# Change if your locker application runs on a different port
# locker_port = 8080  # Uncomment and modify to use a different port

# OPTION 1: Use existing SSH key pair (default)
key_name = "your-key-pair-name"  # Replace with your SSH key pair name

# OPTION 2: Create a new SSH key pair (comment out key_name above and uncomment below)
# create_key_pair = true
# public_key      = "ssh-rsa AAAAB3NzaC1yc2E..."  # Optional: provide public key, or leave commented to auto-generate
# key_name        = "custom-key-name"             # Optional: specify custom name, otherwise auto-generated
# NOTE: If public_key is not provided, a new key pair will be auto-generated and the private key
#       will be securely stored in SSM Parameter Store at: /{environment}/{project}/locker/ssh-private-key

# ============================================================================
# NLB Listeners Configuration
# ============================================================================
# NLB listener configurations for the Network Load Balancer
# Default: TCP on port 80 for secure internal access
nlb_listeners = {
  http = {
    port     = 80
    protocol = "TCP"
  }

  # Example: Add HTTP listener (uncomment if needed)
  # https = {
  #   port     = 443
  #   protocol = "TCP"
  # },

  # Example: Add TLS listener with certificate (uncomment if needed)
  # https_tls = {
  #   port              = 8443
  #   protocol          = "TLS"
  #   certificate_arn   = "arn:aws:acm:eu-central-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  # },

  # Example: Route to custom target group (uncomment if needed)
  # custom_app = {
  #   port              = 9090
  #   protocol          = "TCP"
  #   target_group_arn  = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/custom-tg/1234567890123456"
  # }
}

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
