# ============================================================================
# ArgoCD Management Role - Dev Environment
# ============================================================================
# This configuration deploys the ArgoCD management IAM role:
#   - IAM role with OIDC provider trust for ArgoCD service accounts
#   - Self-assumption capability for role chaining
#   - Cross-account role assumption policy for multi-account deployments
#
# The role enables ArgoCD to manage deployments across multiple AWS accounts.
# ============================================================================

provider "aws" {
  region = var.region
}

module "argocd_management_role" {
  source = "../../../../../modules/application-resources/argocd"

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
  oidc_provider_arns                = var.oidc_provider_arns
  additional_assume_role_statements = var.additional_assume_role_statements

  # Cross-Account Role Assumption
  cross_account_roles       = var.cross_account_roles
  create_assume_role_policy = var.create_assume_role_policy

  # Additional Policies
  additional_policy_arns = var.additional_policy_arns

  # Tags
  common_tags = var.common_tags
}
