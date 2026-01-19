# ============================================================================
# Dev Environment - EU Central 1 - Istio Configuration
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

# VPC ID where security groups will be created
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Subnet IDs for the load balancer (use public subnets for internet-facing ALB)
lb_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy",
  "subnet-zzzzzzzzzzzzzzzzz"
]

# ============================================================================
# EKS Configuration
# ============================================================================

# Name of the EKS cluster where Istio will be deployed
eks_cluster_name = "dev-hyperswitch-eks-cluster"

# ============================================================================
# Istio Configuration
# ============================================================================

# Namespace for Istio components
istio_namespace = "istio-system"

# Whether to create Helm releases
create_helm_releases = true

# Security Group Configuration
create_lb_security_group = true
# Existing security groups to attach to the load balancer
lb_security_groups       = []

# Istio Base Configuration
istio_base = {
  enabled       = true
  release_name  = null  # Uses default: "istio-base"
  chart_repo    = null  # Uses default
  chart_version = null  # Uses default: "1.28.0"
  values        = []
  values_file   = ""
}

# Istiod Configuration
istiod = {
  enabled       = true
  release_name  = null  # Uses default: "istiod"
  chart_repo    = null  # Uses default
  chart_version = null  # Uses default: "1.28.0"
  values        = []
  values_file   = ""
}

# Istio Gateway Configuration
istio_gateway = {
  enabled       = true
  release_name  = null  # Uses default: "istio-gateway"
  chart_repo    = null  # Uses default
  chart_version = null  # Uses default: "1.28.0"
  values        = []
  values_file   = ""
}

# Additional Ingress Annotations
ingress_annotations = {}

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  ManagedBy   = "terraform"
  Environment = "dev"
  Project     = "hyperswitch"
  Component   = "istio"
}
