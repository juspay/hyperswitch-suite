# ============================================================================
# Development Environment - EU Central 1 - Kafka Configuration
# ============================================================================
# This file contains configuration values for the Kafka cluster deployment
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
vpc_id               = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID
broker_subnet_id     = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID for brokers
controller_subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID for controllers

# ============================================================================
# Kafka Cluster Configuration
# ============================================================================
broker_count = 3

# ============================================================================
# Broker Instance Configuration
# ============================================================================
# Kafka broker AMI - should be an ARM-based AMI with Kafka pre-installed
# TODO: Replace with your Kafka broker AMI ID
broker_ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Kafka broker AMI ID

# Instance type - t4g.medium (ARM/Graviton) recommended for Kafka brokers
broker_instance_type = "t4g.medium"

# Root volume for broker OS
broker_root_volume_size = 30
broker_root_volume_type = "gp3"

# Data volume for Kafka broker logs and data
broker_data_volume_size = 10
broker_data_volume_type = "gp3"
broker_data_device_name = "/dev/sdb"

# ============================================================================
# Controller Instance Configuration
# ============================================================================
# Kafka controller AMI - should be an ARM-based AMI with Kafka pre-installed
# TODO: Replace with your Kafka controller AMI ID
controller_ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Kafka controller AMI ID

# Instance type - c7g.medium (ARM/Graviton) recommended for Kafka controllers
controller_instance_type = "c7g.medium"

# Root volume for controller OS
controller_root_volume_size = 30
controller_root_volume_type = "gp3"

# Metadata volume for Kafka controller state
controller_metadata_volume_size = 10
controller_metadata_volume_type = "gp3"
controller_metadata_device_name = "/dev/sdb"

# ============================================================================
# SSH Key Configuration
# ============================================================================
# Set create_key_pair = true to auto-generate a key pair (recommended)
# The private key will be stored in SSM at: /{environment}/{project}/kafka/ssh-private-key
create_key_pair = true

# Optionally provide your own public key (if not provided, key will be auto-generated)
# public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # Replace with your SSH public key

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "kafka"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
