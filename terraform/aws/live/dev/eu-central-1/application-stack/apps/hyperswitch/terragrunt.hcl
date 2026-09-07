include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/application-resources/hyperswitch?ref=hyperswitch-v0.1.1"
}

dependency "eks" {
  config_path = "../../eks-01"

  mock_outputs = {
    cluster_name = "mock-cluster"
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

# dependency "dashboard_integ_buckets" {
#   config_path = "../dashboard-integ-buckets"
# }

inputs = {
  environment  = include.root.locals.environment.full
  region       = include.root.locals.region
  project_name = include.root.locals.project_name

  cluster_service_accounts = {
    "${dependency.eks.outputs.cluster_name}" = [
      {
        namespace = "hyperswitch"
        name      = "hyperswitch-router-role"
      }
    ]
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

  # S3 Dashboard Themes Bucket
  s3_dashboard_themes = {
    create             = true
    versioning_enabled = true
    force_destroy      = false
  }

  # S3 File Uploads Bucket
  s3_file_uploads = {
    create             = true
    versioning_enabled = true
    force_destroy      = false
  }

  # SES Configuration (email-sending role is environment-specific; disabled when unset)
  ses = {
    enabled  = try(values.ses_email_role_arn, null) != null
    role_arn = try(values.ses_email_role_arn, null)
  }

  # Secrets Manager Configuration
  secrets_manager = {
    enabled = true
    secret_arns = [
      "arn:aws:secretsmanager:${include.root.locals.region}:${include.root.locals.account_id}:secret:${include.root.locals.environment.full}/hyperswitch-*"
    ]
  }

  lambda = {
    enabled = !try(values.is_passive, false)
    function_arns = [
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:weekly_payment_report_generator_step_1",
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:weekly_refund_report_generator_step_1",
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:weekly_dispute_report_generator_step_1",
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:weekly_authentication_report_generator_step_1",
      "arn:aws:lambda:${include.root.locals.region}:${include.root.locals.account_id}:function:weekly_payout_report_generator_step_1"
    ]
  }

  # Assume Role Configuration
  assume_role = {
    enabled = false
  }

  # Additional IAM Policy - Integ Dashboard Buckets Access
  # additional_iam_policies = {
  #   integ_dashboard_s3_access = {
  #     policy = jsonencode({
  #       Version = "2012-10-17"
  #       Statement = [
  #         {
  #           Sid    = "AllowIntegDashboardThemesBucketAccess"
  #           Effect = "Allow"
  #           Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
  #           Resource = [
  #             dependency.dashboard_integ_buckets.outputs.s3_dashboard_themes_bucket_arn,
  #             "${dependency.dashboard_integ_buckets.outputs.s3_dashboard_themes_bucket_arn}/*"
  #           ]
  #         },
  #         {
  #           Sid    = "AllowIntegFileUploadsBucketAccess"
  #           Effect = "Allow"
  #           Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
  #           Resource = [
  #             dependency.dashboard_integ_buckets.outputs.s3_file_uploads_bucket_arn,
  #             "${dependency.dashboard_integ_buckets.outputs.s3_file_uploads_bucket_arn}/*"
  #           ]
  #         }
  #       ]
  #     })
  #   }
  # }
}
