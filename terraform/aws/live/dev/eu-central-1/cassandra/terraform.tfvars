# ============================================================================
# Development Environment - EU Central 1 - Cassandra Configuration
# ============================================================================
# This file contains configuration values for the Cassandra cluster deployment
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
vpc_id    = "vpc-xxxxxxxxxxxxxxxxx"  # Replace with your VPC ID
subnet_id = "subnet-xxxxxxxxxxxxxxxxx"  # Replace with your private subnet ID

# ============================================================================
# Cassandra Cluster Configuration
# ============================================================================
cluster_name       = "cassandra-hyperswitch"
node_count         = 3
replication_factor = 3
idle_timeout       = "3600000ms"
default_config_path = "ReadWriteHeavy"

# ============================================================================
# Seed Discovery Configuration
# ============================================================================
# Source code for the seed discovery Lambda function
# This should point to the index.mjs file containing the Lambda handler
# TODO: Replace with the actual path to your Lambda source code
seed_discovery_lambda_source = "file://./index.mjs"  # Replace with actual file path or URL

# VPC Endpoint ID for the API Gateway (execute-api)
# Required for PRIVATE API Gateway endpoint type
# TODO: Replace with your VPC Endpoint ID for API Gateway
api_gateway_vpce_id = "vpce-xxxxxxxxxxxxxxxxx"  # Replace with your execute-api VPCe ID

# ============================================================================
# Instance Configuration
# ============================================================================
# Cassandra AMI - should be ARM-based AMI with Cassandra pre-installed
# The reference setup uses ami-0ec802976c02674c6 (ARM/Graviton)
# TODO: Replace with your Cassandra AMI ID
ami_id = "ami-xxxxxxxxxxxxxxxxx"  # Replace with your Cassandra AMI ID

# Instance type - m7g.large (ARM/Graviton) recommended for Cassandra workloads
# Provides 2 vCPUs, 8 GB RAM with excellent price/performance for Cassandra
instance_type = "m7g.large"

# Additional EBS volume for Cassandra data directory
ebs_volume_size = 100   # GB
ebs_volume_type = "gp3"

# SSH key pair configuration
# Set create_key_pair = true to auto-generate a key pair (recommended)
# The private key will be stored in SSM at: /{environment}/{project}/cassandra/ssh-private-key
create_key_pair = true

# Optionally provide your own public key (if not provided, key will be auto-generated)
# public_key = "ssh-rsa AAAAB3NzaC1yc2E..."  # Replace with your SSH public key

# ============================================================================
# Security Configuration
# ============================================================================
# Cassandra ports (defaults shown - uncomment to customize)
# cassandra_ports = {
#   storage     = 7000  # Inter-node communication
#   storage_ssl = 7001  # SSL inter-node communication
#   jmx         = 7199  # JMX monitoring
#   native      = 9042  # CQL native transport
#   thrift      = 9160  # Thrift client (legacy)
# }

# Cross-module security rules (e.g., EKS -> Cassandra, jump-host -> Cassandra)
# are managed in the security-rules live layer, not here.
# See: live/dev/eu-central-1/security-rules/main.tf

# ============================================================================
# Tag Configuration
# ============================================================================
# Tags used for identifying cluster nodes and ENIs
# These should match the values expected by your seed discovery Lambda
# cluster_tag_name  = "CassandraCluster"   # Tag key for cluster identification
# cluster_tag_value = "cassandra-cluster"  # Tag value for cluster identification
# eni_tag_name      = "CassandraENI"       # Tag key for ENI identification
# eni_tag_value     = "cassandra-eni"      # Tag value for ENI identification

# ============================================================================
# Logging Configuration
# ============================================================================
# CloudWatch log retention in days
log_retention_days = 30

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "cassandra"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
