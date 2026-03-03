provider "aws" {
  region = var.region
}

# =========================================================================
# IAM - ROLE
# =========================================================================
resource "aws_iam_role" "iam_role" {
  name        = "${local.name_prefix}-role"
  description = "IAM role for ${title(var.project_name)} ${title(var.environment)} application"
  path        = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        for cluster_name, statement in local.cluster_oidc_statements : {
          Effect = "Allow"
          Principal = {
            Federated = statement.oidc_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${statement.oidc_url}:aud" = "sts.amazonaws.com"
              "${statement.oidc_url}:sub" = statement.subjects
            }
          }
        }
      ],
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags
}

# =========================================================================
# IAM - KMS POLICY
# =========================================================================
resource "aws_iam_policy" "kms_policy" {
  count = local.kms_enabled ? 1 : 0

  name = "${local.name_prefix}-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSEncryptDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = local.kms_key_arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "kms_policy_attachment" {
  count = local.kms_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.kms_policy[0].arn
}

# =========================================================================
# IAM - S3 POLICY - Dashboard Themes
# =========================================================================
resource "aws_iam_policy" "s3_dashboard_themes_policy" {
  count = local.s3_dashboard_themes_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-dashboard-themes-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDashboardThemesAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${local.s3_dashboard_themes_bucket_arn}/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_dashboard_themes_policy_attachment" {
  count = local.s3_dashboard_themes_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.s3_dashboard_themes_policy[0].arn
}

# =========================================================================
# IAM - S3 POLICY - File Uploads
# =========================================================================
resource "aws_iam_policy" "s3_file_uploads_policy" {
  count = local.s3_file_uploads_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-file-uploads-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFileUploadsAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${local.s3_file_uploads_bucket_arn}/*",
          local.s3_file_uploads_bucket_arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "s3_file_uploads_policy_attachment" {
  count = local.s3_file_uploads_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.s3_file_uploads_policy[0].arn
}

# =========================================================================
# IAM - SES POLICY
# =========================================================================
resource "aws_iam_policy" "ses_policy" {
  count = local.ses_enabled ? 1 : 0

  name = "${local.name_prefix}-ses-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # SES role assumption
      local.ses_role_arn != null ? [
        {
          Sid    = "AllowSESRoleAssume"
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = local.ses_role_arn
        },
        {
          Sid    = "AllowSESTokenOperations"
          Effect = "Allow"
          Action = [
            "sts:GetSessionToken",
            "sts:GetServiceBearerToken"
          ]
          Resource = local.ses_role_arn
        }
      ] : [],
      # SES API operations
      [
        {
          Sid    = "AllowSESOperations"
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
    )
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ses_policy_attachment" {
  count = local.ses_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.ses_policy[0].arn
}

# =========================================================================
# IAM - SECRETS MANAGER POLICY
# =========================================================================
resource "aws_iam_policy" "secrets_manager_policy" {
  count = local.secrets_manager_enabled ? 1 : 0

  name = "${local.name_prefix}-secrets-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.secrets_manager_arns
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  count = local.secrets_manager_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy[0].arn
}

# =========================================================================
# IAM - CROSS-ACCOUNT ASSUME ROLE POLICY
# =========================================================================
resource "aws_iam_policy" "assume_role_policy" {
  count = local.assume_role_enabled ? 1 : 0

  name = "${local.name_prefix}-assume-role-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Specific role ARNs
      length(local.assume_role_arns) > 0 ? [
        {
          Sid    = "AllowAssumeSpecificRoles"
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = local.assume_role_arns
        }
      ] : [],
      # Account-wide role assumption (wildcard)
      local.assume_role_account_id != null ? [
        {
          Sid    = "AllowAssumeAccountRoles"
          Effect = "Allow"
          Action = [
            "sts:AssumeRole"
          ]
          Resource = "arn:aws:iam::${local.assume_role_account_id}:role/*"
        },
        {
          Sid    = "AllowSTSTokenOperations"
          Effect = "Allow"
          Action = [
            "sts:GetSessionToken",
            "sts:GetServiceBearerToken"
          ]
          Resource = "*"
        }
      ] : []
    )
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "assume_role_policy_attachment" {
  count = local.assume_role_enabled ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.assume_role_policy[0].arn
}
