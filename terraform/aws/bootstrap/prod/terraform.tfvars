# ============================================================================
# Production Environment - Terraform Backend Bootstrap Configuration
# ============================================================================
# This file contains the configuration values for the PRODUCTION environment
# backend infrastructure (S3 bucket + DynamoDB table).
#
# ⚠️  PRODUCTION: Review all settings carefully before applying!
#
# Usage:
#   terraform init
#   terraform apply  # Uses values from this file
# ============================================================================

# AWS Region
region = "eu-central-1"

# Environment identifier
environment = "prod"

# Project name (used for tagging)
project_name = "hyperswitch"

# ============================================================================
# S3 Bucket Configuration
# ============================================================================

# Name of the S3 bucket for Terraform state
# Note: Must be globally unique across all AWS accounts
state_bucket_name = "hyperswitch-prod-terraform-state"

# ⚠️ PRODUCTION: Prevent accidental deletion of state bucket
# IMPORTANT: This setting only applies when the bucket is CREATED.
# - If you want deletion protection, set this to FALSE before first apply
# - To change this later, you must manually update the bucket or recreate it
# - Recommended workflow:
#   1. For production: Create with allow_destroy = false (deletion protection ON)
#   2. For testing: Create with allow_destroy = true, then change to false and re-apply
allow_destroy = false

# Server-side encryption algorithm
# Consider using "aws:kms" with a customer-managed key for production
sse_algorithm = "AES256"

# Lifecycle rules (empty = keep all state history)
# Consider adding rules to archive old versions to Glacier for cost optimization
lifecycle_rules = []

# Example lifecycle rule (commented out):
# lifecycle_rules = [
#   {
#     id                            = "archive-old-versions"
#     enabled                       = true
#     prefix                        = ""
#     expiration_days               = null
#     noncurrent_version_expiration = 90  # Delete versions older than 90 days
#     transition = [
#       {
#         days          = 30
#         storage_class = "STANDARD_IA"  # Move to cheaper storage after 30 days
#       }
#     ]
#   }
# ]

# ============================================================================
# DynamoDB Table Configuration
# ============================================================================

# Name of the DynamoDB table for state locking
dynamodb_table_name = "hyperswitch-prod-terraform-state-lock"

# Billing mode (PAY_PER_REQUEST is cost-effective for state locking)
dynamodb_billing_mode = "PAY_PER_REQUEST"

# ⚠️ PRODUCTION: Enable point-in-time recovery for additional safety
enable_dynamodb_pitr = true

# ============================================================================
# Tagging
# ============================================================================

# Additional tags for all resources
tags = {
  ManagedBy   = "terraform"
  Environment = "prod"
  Purpose     = "terraform-state-backend"
  Team        = "DevOps"
  Criticality = "high"
  Backup      = "required"
}
