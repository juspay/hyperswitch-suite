locals {
  # ============================================================================
  # Shared Policies Configuration
  # ============================================================================
  # The following policies are kept as examples for the open source community.
  # These are generated via the shared-policies module and referenced in hyperswitch-app.
  # All resources set to "*" for open source community use.
  # Modify to restrict access to specific resources in production.

  # ===== S3 Policies =====
  hs_s3_sbx_file_uploads = {
    name        = "hs-s3-sbx-file-uploads-policy"
    description = "Policy for sandbox file uploads S3 access"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowPushAndPullToSandboxFileUploadsBucket"
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:GetObjectVersion"
          ]
          Resource = "*"
        }
      ]
    })
  }

  hs_dashboard_themes = {
    name        = "hs-dashboard-themes-policy"
    description = "Policy for dashboard themes S3 access"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "VisualEditor0"
          Effect   = "Allow"
          Action   = ["s3:PutObject", "s3:GetObject"]
          Resource = "*"
        }
      ]
    })
  }

  # ===== SES Policies =====
  ses_send_email_base = {
    name        = "ses-hs-send-email-base-policy"
    description = "Base policy for sending emails via SES"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "ses:ListTemplates",
            "ses:SendEmail",
            "ses:SendTemplatedEmail",
            "ses:SendRawEmail",
            "ses:ListVerifiedEmailAddresses"
          ]
          Resource = "*"
        }
      ]
    })
  }

  hs_ses_assume = {
    name        = "hs-ses-assume-policy"
    description = "Policy for assuming SES role"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "sts:AssumeRole",
            "sts:GetSessionToken",
            "sts:GetServiceBearerToken"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # ===== Lambda Policies =====
  hs_sbx_reports_lambda_invoke = {
    name        = "hs-sbx-reports-lambda-invoke-policy"
    description = "Policy for invoking report generator Lambda functions"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "lambda:ListFunctions",
            "lambda:ListEventSourceMappings",
            "lambda:ListLayerVersions",
            "lambda:ListLayers",
            "lambda:GetAccountSettings",
            "lambda:CreateEventSourceMapping",
            "lambda:ListCodeSigningConfigs",
            "lambda:CreateCodeSigningConfig"
          ]
          Resource = "*"
        },
        {
          Sid    = "VisualEditor1"
          Effect = "Allow"
          Action = [
            "lambda:InvokeFunction",
            "lambda:*"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # ===== STS Policies =====
  hs_sbx_sts_assumerole = {
    name        = "hs-sbx-sts-assumerole"
    description = "Policy for assuming IAM roles"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "VisualEditor0"
          Effect   = "Allow"
          Action   = "sts:AssumeRole"
          Resource = "*"
        },
        {
          Sid    = "VisualEditor1"
          Effect = "Allow"
          Action = [
            "sts:GetSessionToken",
            "sts:GetServiceBearerToken"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # ===== Encryption Service Policy =====
  hs_encryption_service_eso = {
    name        = "hs-encryption-service-sandbox-eso-policy"
    description = "Policy for hyperswitch encryption service sandbox to read AWS secrets"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "VisualEditor0"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # ===== KMS Limited Hyperswitch Policy =====
  kms_limited_hyperswitch = {
    name        = "kms-limited-hyperswitch"
    description = "Limited KMS access for multiple regions"
    path        = "/"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowRegion1KmsKeyUsage"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:CreateGrant"
          ]
          Resource = "*"
        },
        {
          Sid    = "AllowRegion2KmsKeyUsage"
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:CreateGrant"
          ]
          Resource = "*"
        }
      ]
    })
  }

  # Combine all policies
  policies = {
    hs_s3_sbx_file_uploads       = local.hs_s3_sbx_file_uploads
    hs_dashboard_themes          = local.hs_dashboard_themes
    ses_send_email_base          = local.ses_send_email_base
    hs_ses_assume                = local.hs_ses_assume
    hs_sbx_reports_lambda_invoke = local.hs_sbx_reports_lambda_invoke
    hs_sbx_sts_assumerole        = local.hs_sbx_sts_assumerole
    hs_encryption_service_eso    = local.hs_encryption_service_eso
    kms_limited_hyperswitch      = local.kms_limited_hyperswitch
  }
}

module "shared_policies" {
  source = "../../../../../modules/application-resources/shared-policy"

  common_tags = var.common_tags
  policies    = local.policies
}
