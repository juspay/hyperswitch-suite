# ============================================================================
# Development Environment - EU Central 1 - Security Rules Configuration
# ============================================================================
# This file contains cross-module security group rules for the dev environment
# Security groups are created in their respective modules
# This module manages only the connectivity rules between modules
# ============================================================================

# ============================================================================
# Environment Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# Locker Security Group Rules
# ============================================================================
# Ingress rules for locker instance security group
# Note: Traffic from NLB (port 8080) is automatically configured in locker module
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
# Note: Traffic to locker instance (port 8080) is automatically configured in locker module
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
# Squid Proxy Security Group Rules
# ============================================================================
# Ingress rules for squid proxy instance security group
squid_ingress_rules = [
    {
    description = "Allow traffic from EKS worker subnets"
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr        = ["10.X.X.0/21", "10.X.X.0/24"]  # Replace with your EKS worker subnet CIDRs
  },
  # Example 2: Allow SSH from jumpbox security group
  # {
  #   description = "Allow SSH access from external jumpbox"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   sg_id       = ["sg-XXXXXXXXXXXXX"]
  # },
  # Example 3: Allow Prometheus metrics scraping from Prometheus security group
  # {
  #   description = "Allow Prometheus metrics scraping"
  #   from_port   = 9273
  #   to_port     = 9273
  #   protocol    = "tcp"
  #   sg_id       = ["sg-XXXXXXXXXXXXX"]
  # },
]

# Egress rules for squid proxy instance security group
squid_egress_rules = [
    # Allow HTTPS access to the internet
  {
    description = "Allow HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr        = ["0.0.0.0/0"]
  },
  # Example 1: Allow outbound to Wazuh master (CIDR blocks)
  # {
  #   description = "Wazuh master"
  #   from_port   = 1515
  #   to_port     = 1515
  #   protocol    = "tcp"
  #   cidr        = ["10.41.16.0/20"]
  # },
  # Example 2: Allow outbound to ClamAV (Security Group ID)
  # {
  #   description = "ClamAV antivirus service"
  #   from_port   = 3310
  #   to_port     = 3310
  #   protocol    = "tcp"
  #   sg_id       = ["sg-XXXXXXXXXXXXX"]
  # },
  # Example 3: Allow outbound to custom application on non-standard port
  # {
  #   description = "Custom API endpoint"
  #   from_port   = 8443
  #   to_port     = 8443
  #   protocol    = "tcp"
  #   cidr        = ["192.168.1.0/24"]
  # },
]
