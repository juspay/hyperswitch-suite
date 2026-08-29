include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/external-secrets-operator?ref=eso-v0.1.1"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  # Environment & Project Configuration
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  # IAM Role Configuration
  # role_name            = "eso-application-stack"
  # role_description     = "IAM role for External Secrets Operator with access to AWS Secrets Manager"
  # role_path            = "/"
  # max_session_duration = 3600

  # Trust Policy Configuration
  aws_account_id = include.root.locals.account_id

  # OIDC and Service Account Configuration
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      { namespace = "external-secrets-operator", name = "external-secrets-sa" }
    ]
  }

  # Additional Policies
  additional_policy_arns = []

  # Tags
  common_tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "external-secrets-operator"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

}
