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
          name      = "hyperswitch-eso-sa"
          namespace = "hyperswitch-sandbox"
          condition_value = [
            "sts.amazonaws.com",
            "system:serviceaccount:hyperswitch-sandbox:hyperswitch-eso-sa",
          ]
        }
      ]
    }
  }

  # ============================================================================
  # Inline Policies
  # ============================================================================
  # All resources set to "*" for open source community use.
  # Modify to restrict access to specific secrets in production.

  inline_policies = {
    hyperswitch_sandbox_secrets = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

module "eks_iam" {
  source = "../../../../../modules/application-resources/eks-iam"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  app_name     = "eso-hyperswitch"
  role_name    = var.role_name

  oidc_providers = local.oidc_providers

  inline_policies = local.inline_policies

  common_tags = var.common_tags
}
