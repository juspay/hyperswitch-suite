###################
# VPC Network Configuration - Optimized 36-Subnet Plan
# Environment: Development
###################

###################
# Basic Configuration
###################
aws_region = "eu-central-1"
vpc_cidr   = "10.0.0.0/16" # 65,536 IPs

availability_zones = [
  "eu-central-1a",
  "eu-central-1b",
  "eu-central-1c"
]

###################
# Secondary CIDR Blocks (Optional - for EKS pod networking)
###################
# Uncomment if you need dedicated pod networking CIDR
# secondary_cidr_blocks = [
#   "10.1.0.0/16", # EKS pod CIDR - 65,536 IPs
#   "10.2.0.0/16"  # Future expansion
# ]
secondary_cidr_blocks = []

###################
# NAT Gateway Configuration
###################
# Dev: Use single NAT gateway (cost savings ~$70/month)
# Prod: Set to false for HA (one NAT per AZ)
single_nat_gateway = true

###################
# Subnet CIDR Allocations
###################

# PUBLIC TIER - Internet-facing via Internet Gateway
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# External Incoming (ALB, NAT Gateway)
external_incoming_subnet_cidrs = [
  "10.0.64.0/24", # AZ-A: 256 IPs
  "10.0.65.0/24", # AZ-B: 256 IPs
  "10.0.66.0/24"  # AZ-C: 256 IPs
]

# Management (Bastion with Elastic IP)
management_subnet_cidrs = [
  "10.0.67.0/24", # AZ-A: 256 IPs
  "10.0.68.0/24", # AZ-B: 256 IPs
  "10.0.69.0/24"  # AZ-C: 256 IPs
]

# PRIVATE WITH NAT TIER - Egress via NAT Gateway
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# EKS Workers (Main Workload) - /21 for ~2000 IPs per AZ
eks_workers_subnet_cidrs = [
  "10.0.32.0/21", # AZ-A: 2,048 IPs (10.0.32.0 - 10.0.39.255)
  "10.0.40.0/21", # AZ-B: 2,048 IPs (10.0.40.0 - 10.0.47.255)
  "10.0.48.0/21"  # AZ-C: 2,048 IPs (10.0.48.0 - 10.0.55.255)
]
# Total: 6,144 IPs for EKS workers

# Incoming Web Envoy (Proxy Layer)
incoming_envoy_subnet_cidrs = [
  "10.0.88.0/24", # AZ-A: 256 IPs
  "10.0.89.0/24", # AZ-B: 256 IPs
  "10.0.90.0/24"  # AZ-C: 256 IPs
]

# Outgoing Proxy (Squid)
outgoing_proxy_subnet_cidrs = [
  "10.0.91.0/24", # AZ-A: 256 IPs
  "10.0.92.0/24", # AZ-B: 256 IPs
  "10.0.93.0/24"  # AZ-C: 256 IPs
]

# Utils (Lambda, Elasticsearch)
utils_subnet_cidrs = [
  "10.0.94.0/24", # AZ-A: 256 IPs
  "10.0.95.0/24", # AZ-B: 256 IPs
  "10.0.96.0/24"  # AZ-C: 256 IPs
]

# FULLY ISOLATED TIER - No internet access
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# EKS Control Plane (AWS Managed)
eks_control_plane_subnet_cidrs = [
  "10.0.70.0/24", # AZ-A: 256 IPs
  "10.0.71.0/24", # AZ-B: 256 IPs
  "10.0.72.0/24"  # AZ-C: 256 IPs
]

# Database (RDS, Aurora)
database_subnet_cidrs = [
  "10.0.73.0/24", # AZ-A: 256 IPs
  "10.0.74.0/24", # AZ-B: 256 IPs
  "10.0.75.0/24"  # AZ-C: 256 IPs
]

# Locker Database (PCI-DSS Compliant)
locker_database_subnet_cidrs = [
  "10.0.76.0/24", # AZ-A: 256 IPs
  "10.0.77.0/24", # AZ-B: 256 IPs
  "10.0.78.0/24"  # AZ-C: 256 IPs
]

# Locker Server (PCI-DSS Compliant)
locker_server_subnet_cidrs = [
  "10.0.79.0/24", # AZ-A: 256 IPs
  "10.0.80.0/24", # AZ-B: 256 IPs
  "10.0.81.0/24"  # AZ-C: 256 IPs
]

# ElastiCache (Redis, Memcached)
elasticache_subnet_cidrs = [
  "10.0.82.0/24", # AZ-A: 256 IPs
  "10.0.83.0/24", # AZ-B: 256 IPs
  "10.0.84.0/24"  # AZ-C: 256 IPs
]

# Data Stack (Kafka, Analytics) - S3 Endpoint Access
data_stack_subnet_cidrs = [
  "10.0.85.0/24", # AZ-A: 256 IPs
  "10.0.86.0/24", # AZ-B: 256 IPs
  "10.0.87.0/24"  # AZ-C: 256 IPs
]

###################
# VPC Endpoints
###################
# Enable to reduce NAT Gateway data transfer costs by 70-90%
enable_vpc_endpoints = true

###################
# VPC Flow Logs
###################
# Enable for production (security monitoring and compliance)
enable_flow_logs           = false # Set to true for production
flow_logs_destination_type = "cloud-watch-logs"
# flow_logs_destination_arn  = "arn:aws:logs:eu-central-1:ACCOUNT_ID:log-group:/aws/vpc/flow-logs"

###################
# Tags
###################
tags = {
  Environment = "dev"
  Team        = "Infra"
  CostCenter  = "Engineering"
  ManagedBy   = "Terraform"
  Project     = "hyperswitch"
}

###################
# IP Allocation Summary
###################
# Total Allocated:  13,824 IPs (21.1% of VPC)
# Reserved:         51,712 IPs (78.9% for future expansion)
#
# Breakdown by Tier:
# - External Incoming:    768 IPs (3 x 256)
# - Management:           768 IPs (3 x 256)
# - EKS Workers:        6,144 IPs (3 x 2,048) ← Primary capacity
# - Incoming Envoy:       768 IPs (3 x 256)
# - Outgoing Proxy:       768 IPs (3 x 256)
# - Utils:                768 IPs (3 x 256)
# - EKS Control Plane:    768 IPs (3 x 256)
# - Database:             768 IPs (3 x 256)
# - Locker Database:      768 IPs (3 x 256)
# - Locker Server:        768 IPs (3 x 256)
# - ElastiCache:          768 IPs (3 x 256)
# - Data Stack:           768 IPs (3 x 256)
###################
