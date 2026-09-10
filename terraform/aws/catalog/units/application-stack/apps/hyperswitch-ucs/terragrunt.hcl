include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/hyperswitch-ucs?ref=apps-hyperswitch-ucs-v0.1.0"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  app_name     = "ucs"

  # OIDC/IRSA Configuration. The hyperswitch-ucs chart names the service
  # account after the release (<release>-hyperswitch-ucs) unless
  # serviceAccount.name is set; pass the name the deployment actually uses.
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = try(values.kubernetes_namespace, "hyperswitch")
        name      = try(values.service_account_name, "hyperswitch-ucs")
      }
    ]
  }

  assume_role_principals   = []
  aws_managed_policy_names = []

  # Secrets Manager: the chart's External Secrets Operator resources
  # authenticate as the service account above and read these secrets
  # (e.g. the Superposition API token). Disabled when no ARNs are given.
  secrets_manager = {
    enabled     = length(try(values.secrets_manager_secret_arns, [])) > 0
    secret_arns = try(values.secrets_manager_secret_arns, [])
  }

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    Component   = "hyperswitch-ucs"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
