locals {
  # ============================================================================
  # OIDC Providers Configuration
  # ============================================================================
  # The following configurations are kept as examples for the open source community.

  oidc_providers = {
    # ACTIVE CONFIGURATION
    # Set the oidc_provider_arn variable in terraform.tfvars or pass via -var
    # Example: oidc_provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
    eks_cluster = {
      provider_arn = var.oidc_provider_arn
      service_accounts = [
        {
          name      = "encryption-service-eso-sa"
          namespace = "encryption-service-sandbox"
        }
      ]
    }
  }
}

# ============================================================================
# Shared Policies
# ============================================================================
# This policy is generated via the shared-policies folder.
# See ../../shared-policies/main.tf for policy definitions with masked example data.
data "aws_iam_policy" "encryption_service_policy" {
  name = "hs-encryption-service-sandbox-eso-policy"
}

module "eks_iam" {
  source = "../../../../../modules/application-resources/eks-iam"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  app_name     = "encryption-service"
  role_name    = var.role_name

  oidc_providers = merge(local.oidc_providers, var.oidc_providers)

  customer_managed_policy_arns = concat(
    [data.aws_iam_policy.encryption_service_policy.arn],
    var.customer_managed_policy_arns
  )

  common_tags = var.common_tags
}
