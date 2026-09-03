include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../..//modules/application-resources/eks-iam"
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "shared_policies" {
  config_path = "../shared-policies"

  mock_outputs = {
    policy_arns = {
      hs_s3_sbx_file_uploads       = "arn:aws:iam::123456789012:policy/hs-s3-sbx-file-uploads-policy"
      hs_dashboard_themes          = "arn:aws:iam::123456789012:policy/hs-dashboard-themes-policy"
      ses_send_email_base          = "arn:aws:iam::123456789012:policy/ses-hs-send-email-base-policy"
      hs_ses_assume                = "arn:aws:iam::123456789012:policy/hs-ses-assume-policy"
      hs_sbx_reports_lambda_invoke = "arn:aws:iam::123456789012:policy/hs-sbx-reports-lambda-invoke-policy"
      hs_sbx_sts_assumerole        = "arn:aws:iam::123456789012:policy/hs-sbx-sts-assumerole"
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  app_name = "hyperswitch-app"

  oidc_providers = {
    eks_cluster = {
      provider_arn = dependency.eks.outputs.oidc_provider_arn
      conditions = [
        {
          type   = "StringEquals"
          claim  = "aud"
          values = ["sts.amazonaws.com"]
        },
        {
          type  = "StringLike"
          claim = "sub"
          values = [
            "system:serviceaccount:hyperswitch-sandbox:hyperswitch-router-role",
            "system:serviceaccount:uas-sandbox:uas-sandbox-role",
          ]
        },
      ]
    }
  }

  assume_role_principals   = []
  aws_managed_policy_names = []

  customer_managed_policy_arns = [
    dependency.shared_policies.outputs.policy_arns["hs_s3_sbx_file_uploads"],
    dependency.shared_policies.outputs.policy_arns["hs_dashboard_themes"],
    dependency.shared_policies.outputs.policy_arns["ses_send_email_base"],
    dependency.shared_policies.outputs.policy_arns["hs_ses_assume"],
    dependency.shared_policies.outputs.policy_arns["hs_sbx_reports_lambda_invoke"],
    dependency.shared_policies.outputs.policy_arns["hs_sbx_sts_assumerole"],
  ]

  inline_policies = {
    hyperswitch_ses = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ses:SendEmail",
            "ses:SendRawEmail",
          ]
          Resource = "*"
        },
      ]
    })
  }

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
