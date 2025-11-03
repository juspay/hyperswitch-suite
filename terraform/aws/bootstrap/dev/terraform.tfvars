# ============================================================================
# Development Environment - Terraform Backend Bootstrap Configuration
# ============================================================================
# This file contains the configuration values for the development environment
# backend infrastructure (S3 bucket + DynamoDB table).
#
# Usage:
#   terraform init
#   terraform apply  # Uses values from this file
# ============================================================================

# AWS Region
region = "eu-central-1"

# Environment identifier
environment = "dev"

# Project name (used for tagging)
project_name = "hyperswitch"

# ============================================================================
# S3 Bucket Configuration
# ============================================================================

# Name of the S3 bucket for Terraform state
# Note: Must be globally unique across all AWS accounts
state_bucket_name = "hyperswitch-dev-terraform-state"

# Allow destruction of the bucket (useful for dev environment)
# IMPORTANT: This controls the S3 bucket's force_destroy attribute
# - true = Terraform can delete the bucket even if it contains objects
# - false = Terraform will refuse to delete the bucket if it has objects (protection)
# NOTE: This setting only applies when the bucket is CREATED, not when changed later
allow_destroy = true

# Server-side encryption algorithm (AES256 or aws:kms)
sse_algorithm = "AES256"

# Lifecycle rules (empty = keep all state history)
lifecycle_rules = []

# ============================================================================
# DynamoDB Table Configuration
# ============================================================================

# Name of the DynamoDB table for state locking
dynamodb_table_name = "hyperswitch-dev-terraform-state-lock"

# Billing mode (PAY_PER_REQUEST is cost-effective for state locking)
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Point-in-time recovery (disabled for dev to save costs)
enable_dynamodb_pitr = false

# ============================================================================
# Tagging
# ============================================================================

# Additional tags for all resources
tags = {
  ManagedBy   = "terraform"
  Environment = "dev"
  Purpose     = "terraform-state-backend"
  Team        = "Infra"
}
