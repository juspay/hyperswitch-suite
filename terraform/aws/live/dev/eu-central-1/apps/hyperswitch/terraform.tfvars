# ============================================================================
# Development Environment - EU Central 1 - Hyperswitch App Resources Configuration
# ============================================================================
# This file contains configuration values for the Hyperswitch application
# IAM role, KMS keys, S3 buckets and associated policies.
# Modify values as needed for your deployment.
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# EKS OIDC Configuration
# ============================================================================
# Map of EKS cluster names to service accounts that can assume this IAM role.
# TODO: Replace with your actual EKS cluster name and OIDC provider.
# cluster_service_accounts = {
#   "dev-eks-cluster" = [
#     {
#       namespace = "hyperswitch"
#       name      = "hyperswitch-router"
#     },
#     {
#       namespace = "hyperswitch"
#       name      = "hyperswitch-control-center"
#     }
#   ]
# }

# Leave empty - configure with actual cluster details
cluster_service_accounts = {}

# ============================================================================
# KMS Key Configuration
# ============================================================================
# Set create = true to create a new KMS key for encryption
kms = {
  create      = false  # Set to true to create a new KMS key
  description = "KMS key for Hyperswitch dev environment"
  # key_arn = "arn:aws:kms:eu-central-1:XXXXXXXXXXXX:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Provide existing key ARN
}

# ============================================================================
# S3 Dashboard Themes Configuration
# ============================================================================
# Set create = true to create an S3 bucket for dashboard themes
s3_dashboard_themes = {
  create             = false  # Set to true to create S3 bucket
  versioning_enabled = true
  force_destroy      = false
  # bucket_name = "hyperswitch-dev-dashboard-themes"  # Optional custom name
  # bucket_arn = "arn:aws:s3:::existing-bucket-name"  # Use existing bucket
}

# ============================================================================
# S3 File Uploads Configuration
# ============================================================================
# Set create = true to create an S3 bucket for file uploads
s3_file_uploads = {
  create             = false  # Set to true to create S3 bucket
  versioning_enabled = true
  force_destroy      = false
  # bucket_name = "hyperswitch-dev-file-uploads"  # Optional custom name
  # bucket_arn = "arn:aws:s3:::existing-bucket-name"  # Use existing bucket
}

# ============================================================================
# SES Configuration
# ============================================================================
# Set enabled = true to enable SES email sending permissions
ses = {
  enabled  = false  # Set to true to enable SES policy
  # role_arn = "arn:aws:iam::XXXXXXXXXXXX:role/ses-role"  # Optional: SES role to assume
}

# ============================================================================
# Secrets Manager Configuration
# ============================================================================
# Set enabled = true to grant access to Secrets Manager secrets
secrets_manager = {
  enabled     = false  # Set to true to enable Secrets Manager policy
  secret_arns = []     # List of secret ARNs to grant access to
  # secret_arns = [
  #   "arn:aws:secretsmanager:eu-central-1:XXXXXXXXXXXX:secret:hyperswitch/dev/*"
  # ]
}

# ============================================================================
# Lambda Configuration
# ============================================================================
# Set enabled = true to grant Lambda invocation permissions
lambda = {
  enabled       = false  # Set to true to enable Lambda policy
  function_arns = []     # List of Lambda function ARNs to grant access to
}

# ============================================================================
# Cross-Account Assume Role Configuration
# ============================================================================
# Set enabled = true to allow assuming roles in other accounts
assume_role = {
  enabled          = false  # Set to true to enable assume role policy
  target_role_arns = []     # List of role ARNs to allow assuming
  # account_id = "XXXXXXXXXXXX"  # Account ID for wildcard role assumption
}

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "hyperswitch-app-resources"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
