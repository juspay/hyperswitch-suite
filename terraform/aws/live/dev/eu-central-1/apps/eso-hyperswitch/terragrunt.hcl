include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/application-resources/eks-iam"
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  app_name  = "eso-hyperswitch"
  role_name = "hyperswitch-sandbox-eso-irsa"

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
          type   = "StringEquals"
          claim  = "sub"
          values = ["system:serviceaccount:hyperswitch-sandbox:hyperswitch-eso-sa"]
        },
      ]
    }
  }

  inline_policies = {
    hyperswitch_sandbox_secrets = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
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
