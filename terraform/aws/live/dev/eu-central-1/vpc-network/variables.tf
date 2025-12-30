###################
# VPC Network Variables - Optimized Plan
# Based on VPC_NETWORK_OPTIMIZED_PLAN.md
###################

# ============================================================================
# ENVIRONMENT IDENTIFICATION
# ============================================================================
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "Primary VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16" # Provides 65,536 IPs
}

variable "secondary_cidr_blocks" {
  description = "Secondary CIDR blocks for EKS pod networking and expansion"
  type        = list(string)
  default = [
    # Removed - not needed for basic setup
    # Add if you need dedicated pod networking
  ]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default = [
    "eu-central-1a",
    "eu-central-1b",
    "eu-central-1c"
  ]
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway (cost savings for dev)"
  type        = bool
  default     = true # Set to false for production (HA)
}

###################
# External Incoming Subnets (Public - for ALB, NAT Gateway)
# 10.0.64.0/24, 10.0.65.0/24, 10.0.66.0/24 (768 IPs total)
###################
variable "external_incoming_subnet_cidrs" {
  description = "CIDR blocks for external incoming subnets (ALB, NAT Gateway)"
  type        = list(string)
  default = [
    "10.0.64.0/24", # AZ-A: 256 IPs
    "10.0.65.0/24", # AZ-B: 256 IPs
    "10.0.66.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Management Subnets (Public - for Bastion with Elastic IP)
# 10.0.67.0/24, 10.0.68.0/24, 10.0.69.0/24 (768 IPs total)
###################
variable "management_subnet_cidrs" {
  description = "CIDR blocks for management subnets (bastion hosts)"
  type        = list(string)
  default = [
    "10.0.67.0/24", # AZ-A: 256 IPs
    "10.0.68.0/24", # AZ-B: 256 IPs
    "10.0.69.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# EKS Worker Node Subnets (Private with NAT)
# 10.0.32.0/21, 10.0.40.0/21, 10.0.48.0/21 (6,144 IPs total - ~2000 per AZ)
###################
variable "eks_workers_subnet_cidrs" {
  description = "CIDR blocks for EKS worker node subnets (/21 = 2048 IPs per AZ)"
  type        = list(string)
  default = [
    "10.0.32.0/21", # AZ-A: 2,048 IPs (10.0.32.0 - 10.0.39.255)
    "10.0.40.0/21", # AZ-B: 2,048 IPs (10.0.40.0 - 10.0.47.255)
    "10.0.48.0/21"  # AZ-C: 2,048 IPs (10.0.48.0 - 10.0.55.255)
  ]
}

###################
# EKS Control Plane Subnets (Private Isolated)
# 10.0.70.0/24, 10.0.71.0/24, 10.0.72.0/24 (768 IPs total)
###################
variable "eks_control_plane_subnet_cidrs" {
  description = "CIDR blocks for EKS control plane subnets"
  type        = list(string)
  default = [
    "10.0.70.0/24", # AZ-A: 256 IPs
    "10.0.71.0/24", # AZ-B: 256 IPs
    "10.0.72.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Database Subnets (Fully Isolated)
# 10.0.73.0/24, 10.0.74.0/24, 10.0.75.0/24 (768 IPs total)
###################
variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets (RDS, Aurora)"
  type        = list(string)
  default = [
    "10.0.73.0/24", # AZ-A: 256 IPs
    "10.0.74.0/24", # AZ-B: 256 IPs
    "10.0.75.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Locker Database Subnets (PCI-DSS - Fully Isolated)
# 10.0.76.0/24, 10.0.77.0/24, 10.0.78.0/24 (768 IPs total)
###################
variable "locker_database_subnet_cidrs" {
  description = "CIDR blocks for locker database subnets (PCI-DSS compliant)"
  type        = list(string)
  default = [
    "10.0.76.0/24", # AZ-A: 256 IPs
    "10.0.77.0/24", # AZ-B: 256 IPs
    "10.0.78.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Locker Server Subnets (PCI-DSS - Fully Isolated)
# 10.0.79.0/24, 10.0.80.0/24, 10.0.81.0/24 (768 IPs total)
###################
variable "locker_server_subnet_cidrs" {
  description = "CIDR blocks for locker server subnets (PCI-DSS compliant)"
  type        = list(string)
  default = [
    "10.0.79.0/24", # AZ-A: 256 IPs
    "10.0.80.0/24", # AZ-B: 256 IPs
    "10.0.81.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# ElastiCache Subnets (Fully Isolated)
# 10.0.82.0/24, 10.0.83.0/24, 10.0.84.0/24 (768 IPs total)
###################
variable "elasticache_subnet_cidrs" {
  description = "CIDR blocks for ElastiCache subnets (Redis, Memcached)"
  type        = list(string)
  default = [
    "10.0.82.0/24", # AZ-A: 256 IPs
    "10.0.83.0/24", # AZ-B: 256 IPs
    "10.0.84.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Data Stack Subnets (S3 Endpoint Only)
# 10.0.85.0/24, 10.0.86.0/24, 10.0.87.0/24 (768 IPs total)
###################
variable "data_stack_subnet_cidrs" {
  description = "CIDR blocks for data stack subnets (analytics, Kafka)"
  type        = list(string)
  default = [
    "10.0.85.0/24", # AZ-A: 256 IPs
    "10.0.86.0/24", # AZ-B: 256 IPs
    "10.0.87.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Incoming Web Envoy Subnets (Private with NAT)
# 10.0.88.0/24, 10.0.89.0/24, 10.0.90.0/24 (768 IPs total)
###################
variable "incoming_envoy_subnet_cidrs" {
  description = "CIDR blocks for incoming web envoy subnets"
  type        = list(string)
  default = [
    "10.0.88.0/24", # AZ-A: 256 IPs
    "10.0.89.0/24", # AZ-B: 256 IPs
    "10.0.90.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Outgoing Proxy Subnets (Private with NAT)
# 10.0.91.0/24, 10.0.92.0/24, 10.0.93.0/24 (768 IPs total)
###################
variable "outgoing_proxy_subnet_cidrs" {
  description = "CIDR blocks for outgoing proxy subnets (Squid proxy)"
  type        = list(string)
  default = [
    "10.0.91.0/24", # AZ-A: 256 IPs
    "10.0.92.0/24", # AZ-B: 256 IPs
    "10.0.93.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# Utils Subnets (Lambda, Elasticsearch - Private with NAT)
# 10.0.94.0/24, 10.0.95.0/24, 10.0.96.0/24 (768 IPs total)
###################
variable "utils_subnet_cidrs" {
  description = "CIDR blocks for utils subnets (Lambda, Elasticsearch)"
  type        = list(string)
  default = [
    "10.0.94.0/24", # AZ-A: 256 IPs
    "10.0.95.0/24", # AZ-B: 256 IPs
    "10.0.96.0/24"  # AZ-C: 256 IPs
  ]
}

###################
# VPC Endpoints
###################
variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services (reduces NAT costs)"
  type        = bool
  default     = true
}

###################
# VPC Flow Logs
###################
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for security monitoring"
  type        = bool
  default     = false # Enable in production
}

variable "flow_logs_destination_arn" {
  description = "ARN of S3 bucket or CloudWatch Log Group for flow logs"
  type        = string
  default     = ""
}

variable "flow_logs_destination_type" {
  description = "Destination type for flow logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

###################
# Tags
###################
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    CostCenter = "Engineering"
  }
}

###################
# Subnet Allocation Summary
###################
# Total Allocated: 13,824 IPs (21.1% of 65,536)
# Reserved:        51,712 IPs (78.9% for future expansion)
#
# Breakdown:
# - External Incoming:    768 IPs (3 x /24)
# - Management:           768 IPs (3 x /24)
# - EKS Workers:        6,144 IPs (3 x /21) ← Primary capacity
# - EKS Control Plane:    768 IPs (3 x /24)
# - Database:             768 IPs (3 x /24)
# - Locker Database:      768 IPs (3 x /24)
# - Locker Server:        768 IPs (3 x /24)
# - ElastiCache:          768 IPs (3 x /24)
# - Data Stack:           768 IPs (3 x /24)
# - Incoming Envoy:       768 IPs (3 x /24)
# - Outgoing Proxy:       768 IPs (3 x /24)
# - Utils:                768 IPs (3 x /24)
###################
