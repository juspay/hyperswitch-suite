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
          name      = "grafana"
          namespace = "monitoring"
        }
      ]
    }
  }

  aws_managed_policy_names = [
    "AWSXrayReadOnlyAccess",
    "CloudWatchReadOnlyAccess"
  ]
}

module "eks_iam" {
  source = "../../../../../modules/application-resources/eks-iam"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  app_name     = "grafana"
  role_name    = var.role_name

  oidc_providers = local.oidc_providers

  aws_managed_policy_names = local.aws_managed_policy_names

  common_tags = var.common_tags
}
