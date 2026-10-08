include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/hyperswitch?ref=hyperswitch-v0.2.0"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCK"
    cluster_name      = "mock-cluster"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "hyperswitch-primary" {
  config_path = try(values.primary_hyperswitch_config_path, try("../../../../${values.primary_region}/application-stack/apps/hyperswitch", null))
  enabled     = try(values.is_passive, false)

  mock_outputs = {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# Replica dashboard buckets (composition/s3); gated on the *_s3_config_path values.
dependency "dashboard_bucket" {
  config_path = try(values.dashboard_s3_config_path, "")
  enabled     = try(values.dashboard_s3_config_path, null) != null

  mock_outputs = {
    source_bucket_arn  = "arn:aws:s3:::mock-dashboard"
    replica_bucket_arn = "arn:aws:s3:::mock-dashboard-replica"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "file_uploads_bucket" {
  config_path = try(values.file_uploads_s3_config_path, "")
  enabled     = try(values.file_uploads_s3_config_path, null) != null

  mock_outputs = {
    source_bucket_arn  = "arn:aws:s3:::mock-file-uploads"
    replica_bucket_arn = "arn:aws:s3:::mock-file-uploads-replica"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  # A stack that runs several deployments on one cluster (each in its own
  # namespace) passes the full list via `service_accounts`; the default is the
  # single-deployment shape.
  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = {
      oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
      service_accounts = try(values.service_accounts, [
        {
          namespace = try(values.kubernetes_namespace, "hyperswitch")
          name      = try(values.service_account_name, "hyperswitch-router-role")
        }
      ])
    }
  }

  tags = {
    Environment = include.root.locals.environment.full
    Project     = include.root.locals.project_name
    Component   = "hyperswitch"
    ManagedBy   = "terraform-IaC"
    Region      = include.root.locals.region
  }

  # KMS Configuration
  kms = {
    create              = true
    description         = "KMS key for Hyperswitch application"
    multi_region        = true
    create_replica      = try(values.is_passive, false)
    primary_key_arn     = try(dependency.hyperswitch-primary.outputs.kms_key_arn, null)
    enable_key_rotation = true
    aliases             = ["${include.root.locals.environment.full}-router-key"]
  }

  # Create own bucket, or reference the replica (create=false) when wired.
  s3_dashboard_themes = {
    create             = try(values.dashboard_s3_config_path, null) == null
    bucket_arn         = try(dependency.dashboard_bucket.outputs.replica_bucket_arn, null)
    versioning_enabled = try(values.s3_dashboard_themes_versioning_enabled, true)
    force_destroy      = try(values.s3_dashboard_themes_force_destroy, false)
  }

  s3_file_uploads = {
    create             = try(values.file_uploads_s3_config_path, null) == null
    bucket_arn         = try(dependency.file_uploads_bucket.outputs.replica_bucket_arn, null)
    versioning_enabled = try(values.s3_file_uploads_versioning_enabled, true)
    force_destroy      = try(values.s3_file_uploads_force_destroy, false)
  }

  # SES Configuration (email-sending role is environment-specific; disabled when unset)
  ses = {
    enabled  = try(values.ses_email_role_arn, null) != null
    role_arn = try(values.ses_email_role_arn, null)
  }

  # Secrets Manager Configuration. A stack whose deployments read secrets
  # under several prefixes (one per deployment) overrides the ARN list via
  # `secrets_manager_secret_arns`.
  secrets_manager = {
    enabled = true
    secret_arns = try(values.secrets_manager_secret_arns, [
      "arn:aws:secretsmanager:${include.root.locals.region}:${include.root.locals.account_id}:secret:${include.root.locals.environment.full}/hyperswitch-*"
    ])
  }

  lambda = {
    # The router invokes the reporting step_1 lambdas. They normally live in
    # the active region only, but a stack that hosts them regardless (e.g. a
    # passive region the lambda stack migrated to) opts in via values.
    enabled = try(values.enable_reporting_lambda_invoke, !try(values.is_passive, false))
    function_arns = [
      for fn in concat([
        "weekly_payment_report_generator_step_1",
        "weekly_refund_report_generator_step_1",
        "weekly_dispute_report_generator_step_1",
        "weekly_authentication_report_generator_step_1",
        "weekly_payout_report_generator_step_1",
        "weekly_relay_report_generator_step_1",
      ], try(values.extra_reporting_lambda_invoke_function_names, [])) :
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:${fn}"
    ]
  }

  # Assume Role Configuration
  assume_role = {
    enabled = false
  }

  # Bucket access is granted by the module via the s3_* inputs above.
}
