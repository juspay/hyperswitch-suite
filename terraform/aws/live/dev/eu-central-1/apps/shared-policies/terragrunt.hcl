include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../../modules/application-resources/shared-policy"
}

locals {


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

inputs = {
  policies = local.policies

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
