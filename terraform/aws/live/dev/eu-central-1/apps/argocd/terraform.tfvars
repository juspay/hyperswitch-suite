# ============================================================================
# Dev Environment - EU Central 1 - ArgoCD Configuration
# ============================================================================
# This file contains configuration values for the dev environment ArgoCD role
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

# Name of the ArgoCD management role
# If null, defaults to {project_name}-{environment}-argocd-management-role
role_name = "argocd-management-role"

# Role description
role_description = "IAM role for ArgoCD to manage cross-account deployments in dev environment"

# Maximum session duration (1 hour)
max_session_duration = 3600

# ============================================================================
# Trust Policy Configuration
# ============================================================================

# AWS Account ID where this role is created
# Replace with your actual AWS account ID
aws_account_id = "ACCOUNT_ID"

# ============================================================================
# OIDC and Service Account Configuration (Multi-Cluster Support)
# ============================================================================

# Map of EKS clusters to their service accounts that can assume this role
# Each service account must specify namespace and name
cluster_service_accounts = {
  "dev-eks-cluster" = [
    { namespace = "argocd", name = "argocd-application-controller" },
    { namespace = "argocd", name = "argocd-applicationset-controller" },
    { namespace = "argocd", name = "argocd-server" }
  ]
  # Add additional clusters as needed:
  # "dev-eks-cluster-2" = [
  #   { namespace = "argocd", name = "argocd-application-controller" },
  #   { namespace = "argocd", name = "argocd-server" }
  # ]
}

# Map of cluster names to their OIDC provider ARNs
# Keys must match those in cluster_service_accounts
# Format: arn:aws:iam::{account-id}:oidc-provider/oidc.eks.{region}.amazonaws.com/id/{oidc-id}
oidc_provider_arns = {
  "dev-eks-cluster" = "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XYZ1234567890"
  # "dev-eks-cluster-2" = "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/ABC0987654321"
}

# Additional custom assume role policy statements
# Use this to add custom trust relationships like self-assume for role chaining
# 
# Self-assume configuration (enables role chaining):
# - Allows the role to assume itself for multi-hop deployments
# - Update the PrincipalArn condition to match your role's ARN
# 
# To disable self-assume, remove or comment out the statement below
additional_assume_role_statements = [
  {
    Sid    = "ExplicitSelfRoleAssumption"
    Effect = "Allow"
    Principal = {
      AWS = "*"
    }
    Action = "sts:AssumeRole"
    Condition = {
      ArnLike = {
        "aws:PrincipalArn" = "arn:aws:iam::ACCOUNT_ID:role/argocd-management-role"
      }
    }
  }
]

# ============================================================================
# Cross-Account Role Configuration
# ============================================================================

# List of cross-account role ARNs that ArgoCD can assume
# Example from user's request:
cross_account_roles = [
  "arn:aws:iam::ACCOUNT_ID:role/dev-hyperswitch-argocd-cross-account",
  "arn:aws:iam::ACCOUNT_ID:role/sbx-hyperswitch-argocd-cross-account"
]

# Create and attach the assume role policy
create_assume_role_policy = true

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
  Component   = "argocd"
}
