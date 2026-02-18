locals {
  # ============================================================================
  # OIDC Providers Configuration
  # ============================================================================
  # The following configurations are kept as examples for the open source community.
  # Uncomment and modify as needed for your specific EKS cluster setup.

  oidc_providers = {
    # EXAMPLE 1: EKS cluster with router service account (Simple configuration)
    # eks_cluster_1 = {
    #   provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
    #   service_accounts = [
    #     {
    #       name      = "router-role"
    #       namespace = "router"
    #     }
    #   ]
    # }

    # EXAMPLE 2: Multiple service accounts with StringEquals
    # eks_cluster_2 = {
    #   provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
    #   service_accounts = [
    #     {
    #       name      = "router-role"
    #       namespace = "router"
    #     },
    #     {
    #       name      = "uas-role"
    #       namespace = "sandbox-uas"
    #     }
    #   ]
    # }

    # EXAMPLE 3: Multiple service accounts with mixed conditions
    # eks_cluster_3 = {
    #   provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
    #   service_accounts = [
    #     {
    #       name      = "router-role"
    #       namespace = "router"
    #       condition_value = [
    #         "system:serviceaccount:router:router-role",
    #         "system:serviceaccount:hyperswitch-sandbox:hyperswitch-router-role"
    #       ]
    #     },
    #     {
    #       name           = "uas-role"
    #       namespace      = "sandbox-uas"
    #       condition_type = "StringLike"
    #       condition_value = [
    #         "system:serviceaccount:sandbox-uas:uas-role",
    #         "system:serviceaccount:uas-sandbox:uas-sandbox-role"
    #       ]
    #     }
    #   ]
    # }

    # EXAMPLE 4: Multiple service accounts in single condition
    # eks_cluster_4 = {
    #   provider_arn = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
    #   service_accounts = [
    #     {
    #       name      = "multi-service"
    #       namespace = "hyperswitch-sandbox"
    #       condition_value = [
    #         "system:serviceaccount:hyperswitch-sandbox:hyperswitch-router-role",
    #         "system:serviceaccount:sandbox-uas:uas-role",
    #         "system:serviceaccount:uas-sandbox:uas-sandbox-role"
    #       ]
    #     }
    #   ]
    # }

    # ACTIVE CONFIGURATION
    # Set the oidc_provider_arn variable in terraform.tfvars or pass via -var
    eks_cluster = {
      provider_arn = var.oidc_provider_arn
      service_accounts = [
        {
          name      = "router-role"
          namespace = "router"
          condition_value = [
            "system:serviceaccount:hyperswitch-sandbox:hyperswitch-router-role",
            "sts:AssumeRole"
          ]
        },
        {
          name           = "uas-role"
          namespace      = "sandbox-uas"
          condition_type = "StringLike"
          condition_value = [
            "system:serviceaccount:uas-sandbox:uas-sandbox-role",
            "sts:AssumeRole"
          ]
        }
      ]
    }
  }

  # ============================================================================
  # Assume Role Principals
  # ============================================================================
  # Previously used for EC2 and cross-account role assumptions.
  # Now using OIDC with EKS API and OIDC-based access control above.
  # Kept as example for reference.

  # assume_role_principals = [
  #   {
  #     type        = "Service"
  #     identifiers = ["ec2.amazonaws.com"]
  #   },
  #   {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::XXXXXXXXXXXX:role/YOUR_ROLE_NAME"]
  #   }
  # ]

  assume_role_principals = []

  aws_managed_policy_names = []

  customer_managed_policy_arns = []

  inline_policies = {
    hyperswitch_ses = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ses:SendEmail",
            "ses:SendRawEmail"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

# ============================================================================
# Shared Policies
# ============================================================================
# These policies are generated via the shared-policies folder.
# See ../shared-policies/main.tf for policy definitions with masked example data.
data "aws_iam_policy" "shared_policies" {
  for_each = toset([
    "hs-s3-sbx-file-uploads-policy",
    "hs-dashboard-themes-policy",
    "ses-hs-send-email-base-policy",
    "hs-ses-assume-policy",
    "hs-sbx-reports-lambda-invoke-policy",
    "hs-sbx-sts-assumerole"
  ])

  name = each.value
}

module "eks_iam" {
  source = "../../../../../modules/application-resources/eks-iam"

  region       = var.region
  environment  = var.environment
  project_name = var.project_name
  app_name     = "hyperswitch-app"

  oidc_providers           = local.oidc_providers
  assume_role_principals   = local.assume_role_principals
  aws_managed_policy_names = local.aws_managed_policy_names

  customer_managed_policy_arns = concat(
    [for policy in data.aws_iam_policy.shared_policies : policy.arn],
    local.customer_managed_policy_arns
  )

  inline_policies = local.inline_policies
  common_tags     = var.common_tags
}
