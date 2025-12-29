# ============================================================================
# Development Environment - EU Central 1 - Recon Configuration
# ============================================================================
# This file contains configuration values for the recon service deployment
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# KMS Configuration
# ============================================================================
# KMS key ARN for S3 bucket encryption
# Replace with your KMS key ARN
kms_key_arn = "arn:aws:kms:eu-central-1:XXXXXXXXXXXX:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# ============================================================================
# OIDC Configuration for EKS IRSA
# ============================================================================
# OIDC provider ARN for your EKS cluster
# Replace with your EKS OIDC provider ARN
oidc_provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.<region>.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXX"

# OIDC provider ID (extract from the ARN above, format: oidc.eks.<region>.amazonaws.com/id/<ID>)
oidc_provider_id = "oidc.eks.<region>.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXX"

# Kubernetes service accounts that can assume the recon IAM role
# Format: system:serviceaccount:<namespace>:<service-account-name>
service_accounts = [
  "system:serviceaccount:recon:recon-role",
]

# ============================================================================
# S3 Configuration
# ============================================================================
# S3 bucket name (optional - if not provided, will auto-generate based on environment and account)
# s3_bucket_name = "custom-recon-bucket-name"

# Enable versioning for S3 bucket (recommended for production)
enable_s3_versioning = true

# Allow force destroy of S3 bucket even if it contains objects
# Set to true for dev/test environments, false for production
s3_force_destroy = true

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  Environment = "development"
  Project     = "hyperswitch"
  Component   = "recon"
  ManagedBy   = "terraform-IaC"
  Region      = "eu-central-1"
}
