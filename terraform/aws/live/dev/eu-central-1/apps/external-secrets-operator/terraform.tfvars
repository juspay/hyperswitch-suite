# ============================================================================
# Dev Environment - EU Central 1 - External Secrets Operator Configuration
# ============================================================================
# This file contains configuration values for the dev environment
# External Secrets Operator IAM role
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# IAM Role Configuration
# ============================================================================

# Name of the External Secrets Operator role
# If null, defaults to {project_name}-{environment}-external-secrets-role
role_name = "hyperswitch-dev-external-secrets-operator-role"

# Role description
role_description = "IAM role for External Secrets Operator to access AWS Secrets Manager in dev environment"

# Maximum session duration (1 hour)
max_session_duration = 3600

# ============================================================================
# Trust Policy Configuration
# ============================================================================

# AWS Account ID where this role is created
# Replace with your actual AWS account ID
aws_account_id = "701342709052"

# ============================================================================
# OIDC and Service Account Configuration (Multi-Cluster Support)
# ============================================================================

# Map of EKS clusters to their service accounts that can assume this role
# Each service account must specify namespace and name
cluster_service_accounts = {
  "dev-eks-cluster" = [
    { namespace = "external-secrets-operator", name = "external-secrets-sa" }
  ]
  # Add additional clusters as needed:
  # "dev-eks-cluster-2" = [
  #   { namespace = "external-secrets-operator", name = "external-secrets-sa" }
  # ]
}

# Additional custom assume role policy statements (if needed)
additional_assume_role_statements = []

# ============================================================================
# Additional Configuration
# ============================================================================

# Additional managed policy ARNs to attach (if any)
additional_policy_arns = []

# Common tags to apply to all resources
common_tags = {
  Project     = "hyperswitch"
  Environment = "dev"
  ManagedBy   = "terraform"
  Component   = "external-secrets-operator"
}