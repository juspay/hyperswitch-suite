include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/invokr?ref=invokr-v0.1.1"
}

dependency "eks" {
  config_path = try(values.eks_config_path, "../../eks-01")

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCK"
    cluster_name      = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "vpc" {
  enabled     = try(values.create_database, false)
  config_path = try(values.vpc_config_path, "../../../vpc-network")

  mock_outputs = {
    vpc_id              = "vpc-12345678"
    database_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  app_name     = "invokr"

  create_iam_role                   = true
  enable_application_kms_decryption = true
  role_name                         = try(values.role_name, null)
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = {
      oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
      service_accounts = try(values.service_accounts, [
        {
          namespace = try(values.kubernetes_namespace, "invokr")
          name      = try(values.service_account_name, "invokr")
        }
      ])
    }
  }

  # The module supplies only key-scoped Decrypt/DescribeKey permissions.
  assume_role_principals       = []
  aws_managed_policy_names     = []
  customer_managed_policy_arns = []
  inline_policies              = {}

  kms = merge({
    create              = try(values.kms.key_arn, null) == null
    enable_key_rotation = true
    multi_region        = false
  }, try(values.kms, {}))

  # An optional empty container; ciphertext delivery remains outside Terraform.
  create_application_secret                  = try(values.create_application_secret, false)
  existing_application_secret_arn            = try(values.existing_application_secret_arn, null)
  application_secret_name                    = try(values.application_secret_name, "${include.root.locals.environment.full}/${include.root.locals.project_name}/invokr")
  application_secret_description             = try(values.application_secret_description, null)
  application_secret_kms_key_id              = try(values.application_secret_kms_key_id, null)
  application_secret_recovery_window_in_days = try(values.application_secret_recovery_window_in_days, 7)
  application_secret_tags                    = try(values.application_secret_tags, {})

  create_database = try(values.create_database, false)
  # No implicit sizing or default parameter group: pg_cron is validated by the module.
  database_config = try(values.create_database, false) ? merge(
    {
      manage_master_user_password = true
      deletion_protection         = true
    },
    values.database_config,
    {
      vpc_id            = dependency.vpc.outputs.vpc_id
      subnet_ids        = dependency.vpc.outputs.database_subnet_ids
      cluster_instances = values.database_config.cluster_instances
    }
  ) : null

  tags = merge({
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }, try(values.tags, {}))
}
