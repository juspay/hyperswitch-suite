# ============================================================================
# Terraform Backend Bootstrap - Production Environment
# ============================================================================
# This creates the S3 bucket and DynamoDB table needed for Terraform remote
# state management and locking for the production environment.
#
# Run this FIRST before setting up any other infrastructure:
#   terraform init
#   terraform apply
#
# After this completes, you can configure your live deployments to use this
# backend for state storage and locking.
# ============================================================================

provider "aws" {
  region = var.region
}

# Create the complete Terraform backend infrastructure
module "terraform_backend" {
  source = "../../modules/composition/terraform-backend"

  environment  = var.environment
  project_name = var.project_name

  # S3 Configuration
  state_bucket_name = var.state_bucket_name
  allow_destroy     = var.allow_destroy
  sse_algorithm     = var.sse_algorithm
  lifecycle_rules   = var.lifecycle_rules

  # DynamoDB Configuration
  dynamodb_table_name   = var.dynamodb_table_name
  dynamodb_billing_mode = var.dynamodb_billing_mode
  enable_dynamodb_pitr  = var.enable_dynamodb_pitr

  tags = var.tags
}
