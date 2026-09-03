include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../..//modules/application-resources/argocd"
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    cluster_name      = "dev-hyperswitch-cluster-01"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  role_name            = "argocd-management-role"
  role_description     = "IAM role for ArgoCD to manage cross-account deployments in dev environment"
  role_path            = "/"
  max_session_duration = 3600

  aws_account_id = include.root.locals.account_id

  cluster_service_accounts = {
    (dependency.eks.outputs.cluster_name) = [
      { namespace = "argocd", name = "argocd-application-controller" },
      { namespace = "argocd", name = "argocd-applicationset-controller" },
      { namespace = "argocd", name = "argocd-server" },
    ]
  }

  oidc_provider_arns = {
    (dependency.eks.outputs.cluster_name) = dependency.eks.outputs.oidc_provider_arn
  }

  additional_assume_role_statements = [
    {
      Sid    = "ExplicitSelfRoleAssumption"
      Effect = "Allow"
      Principal = {
        AWS = "*"
      }
      Action = "sts:AssumeRole"
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${include.root.locals.account_id}:role/argocd-management-role"
        }
      }
    },
  ]

  cross_account_roles = [
    "arn:aws:iam::${include.root.locals.account_id}:role/dev-hyperswitch-argocd-cross-account",
    "arn:aws:iam::${include.root.locals.account_id}:role/sbx-hyperswitch-argocd-cross-account",
  ]

  create_assume_role_policy = true
  additional_policy_arns    = []

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
    Component   = "argocd"
  }
}
