include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCK"
    cluster_name      = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/otel-collector?ref=tf/app/otel-v0.2.0"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name
  app_name     = "otel"

  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = {
      oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
      service_accounts = [
        {
          namespace = try(values.kubernetes_namespace, "monitoring")
          name      = try(values.service_account_name, "otel-collector")
        }
      ]
    }
  }

  aws_managed_policy_names = [
    "AWSXRayDaemonWriteAccess"
  ]

  assume_role_principals = []

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
