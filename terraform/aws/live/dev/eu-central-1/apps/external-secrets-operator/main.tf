# ============================================================================
# External Secrets Operator IAM Role - Dev Environment
# ============================================================================
# This configuration deploys the External Secrets Operator IAM role:
#   - IAM role with OIDC provider trust for External Secrets service account
#   - Secrets Manager access policy (GetSecretValue, DescribeSecret)
#
# The role enables External Secrets Operator to sync secrets from AWS Secrets Manager
# to Kubernetes secrets.
# ============================================================================

provider "aws" {
  region = var.region
}

module "external_secrets_operator" {
  source = "../../../../../modules/application-resources/external-secrets-operator"

  # Environment & Project Configuration
  region       = var.region
  environment  = var.environment
  project_name = var.project_name

  # IAM Role Configuration
  role_name            = var.role_name
  role_description     = var.role_description
  role_path            = var.role_path
  max_session_duration = var.max_session_duration

  # Trust Policy Configuration
  aws_account_id = var.aws_account_id

  # OIDC and Service Account Configuration
  cluster_service_accounts          = var.cluster_service_accounts
  additional_assume_role_statements = var.additional_assume_role_statements

  # Additional Policies
  additional_policy_arns = var.additional_policy_arns

  # Tags
  common_tags = var.common_tags
}
