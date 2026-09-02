include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/decision-engine?ref=apps-decision-engine-v0.1.2"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "hyperswitch" {
  config_path = "../hyperswitch"

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  region       = include.root.locals.region
  environment  = include.root.locals.environment.full
  project_name = include.root.locals.project_name
  app_name     = "decision-engine"

  # OIDC/IRSA Configuration
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "decision-engine"
        name      = "decision-engine-sa"
      }
    ]
  }

  assume_role_principals   = []
  aws_managed_policy_names = []

  # KMS Permissions for encryption/decryption
  inline_policies = {
    kms-encrypt-decrypt = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "KMSPermissions"
          Effect   = "Allow"
          Action   = ["kms:Decrypt", "kms:Encrypt"]
          Resource = [dependency.hyperswitch.outputs.kms_key_arn]
        }
      ]
    })
  }

  # Secrets Manager
  secrets_manager_secret_arns = []

  # S3 Bucket Configuration
  s3_bucket = {
    enabled            = true
    bucket_name        = "hyperswitch-decision-engine-${include.root.locals.environment.full}-${include.root.locals.region}"
    force_destroy      = false
    versioning_enabled = true
    lifecycle_rules = [
      {
        id                            = "noncurrent-version-expiration"
        enabled                       = true
        prefix                        = ""
        expiration_days               = null
        noncurrent_version_expiration = 30
        transition                    = []
      }
    ]
  }

  # SES Configuration (email-sending role is environment-specific; disabled when unset)
  ses = {
    enabled  = try(values.ses_email_role_arn, null) != null
    role_arn = try(values.ses_email_role_arn, null)
  }

  tags = {
    Project     = include.root.locals.project_name
    Environment = include.root.locals.environment.full
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }
}
