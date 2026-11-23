# ============================================================================
# Development Environment - EU Central 1 - Clickhouse Configuration
# ============================================================================
# This file contains configuration values for the Clickhouse cluster deployment
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
vpc_id           = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID
keeper_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID for keepers
server_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID for servers

# ============================================================================
# Keeper Configuration
# ============================================================================
keeper_count = 3

# Clickhouse keeper AMI - should be an ARM-based AMI with Clickhouse pre-installed
# TODO: Replace with your Clickhouse keeper AMI ID
keeper_ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Clickhouse keeper AMI ID

# Instance type - c7g.medium (ARM/Graviton) recommended for Clickhouse keepers
keeper_instance_type = "c7g.medium"

# Root volume for keeper OS
keeper_root_volume_size = 30
keeper_root_volume_type = "gp3"

# Data volume for Clickhouse keeper state
keeper_data_volume_size = 10
keeper_data_volume_type = "gp3"
keeper_data_device_name = "/dev/sdb"

# ============================================================================
# Server Configuration
# ============================================================================
server_count = 2

# Clickhouse server AMI - should be an ARM-based AMI with Clickhouse pre-installed
# TODO: Replace with your Clickhouse server AMI ID
server_ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Clickhouse server AMI ID

# Instance type - r7g.large (ARM/Graviton) recommended for Clickhouse servers (memory optimized)
server_instance_type = "r7g.large"

# Root volume for server OS (larger for Clickhouse data directory)
server_root_volume_size = 200
server_root_volume_type = "gp3"

# Data volume for Clickhouse server data
server_data_volume_size = 20
server_data_volume_type = "gp3"
server_data_device_name = "/dev/sdb"

# ============================================================================
# SSH Key Configuration
# ============================================================================
# Set create_key_pair = true to auto-generate a key pair (recommended)
# The private key will be stored in SSM at: /{environment}/{project}/clickhouse/ssh-private-key
create_key_pair = true

# Optionally provide your own public key (if not provided, key will be auto-generated)
# public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # Replace with your SSH public key

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "clickhouse"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
