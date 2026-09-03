include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../..//modules/application-resources/external-secrets-operator"
}

dependency "eks" {
  config_path = "../../eks"

  mock_outputs = {
    cluster_name = "dev-hyperswitch-cluster-01"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.short
  project_name = include.root.locals.project_name

  role_name            = "hyperswitch-dev-external-secrets-operator-role"
  role_description     = "IAM role for External Secrets Operator to access AWS Secrets Manager in dev environment"
  role_path            = "/"
  max_session_duration = 3600

  aws_account_id = include.root.locals.account_id

  cluster_service_accounts = {
    (dependency.eks.outputs.cluster_name) = [
      { namespace = "external-secrets-operator", name = "external-secrets-sa" },
    ]
  }

  additional_assume_role_statements = []
  additional_policy_arns            = []

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
    Component   = "external-secrets-operator"
  }
}
