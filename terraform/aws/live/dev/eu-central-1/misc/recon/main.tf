# ============================================================================
# Recon Deployment - Dev Environment
# ============================================================================
# This configuration deploys the Hyperswitch Recon service infrastructure:
#   - IAM role with OIDC-based trust policy for EKS service accounts
#   - S3 bucket for recon data storage with encryption
#   - IAM policies for KMS and S3 access
#
# Access Method: Via Kubernetes service accounts using IRSA
# Encryption: KMS encryption for S3 bucket
# ============================================================================

provider "aws" {
  region = var.region
}

# Recon Module
module "recon" {
  source = "../../../../modules/composition/misc/recon"

  environment  = var.environment
  project_name = var.project_name

  # OIDC Configuration
  oidc_provider_arn = var.oidc_provider_arn
  oidc_provider_id  = var.oidc_provider_id
  service_accounts  = var.service_accounts

  # KMS Configuration
  kms_key_arn = var.kms_key_arn

  # S3 Configuration
  s3_bucket_name       = var.s3_bucket_name
  enable_s3_versioning = var.enable_s3_versioning
  s3_force_destroy     = var.s3_force_destroy

  # Tags
  tags = var.common_tags
}
