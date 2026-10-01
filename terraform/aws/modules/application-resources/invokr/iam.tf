resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name                  = coalesce(var.role_name, "${local.name_prefix}-role")
  description           = coalesce(var.role_description, "IAM role for ${title(var.app_name)} ${title(var.environment)} application")
  path                  = var.role_path
  max_session_duration  = var.max_session_duration
  force_detach_policies = var.force_detach_policies

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        for statement in values(local.cluster_oidc_statements) : {
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
      local.assume_role_principals_enabled ? [
        {
          Effect = "Allow"
          Principal = {
            AWS = var.assume_role_principals
          }
          Action = "sts:AssumeRole"
        }
      ] : [],
      var.additional_assume_role_statements
    )
  })

  tags = local.common_tags

  lifecycle {
    precondition {
      condition = (
        local.oidc_enabled ||
        local.assume_role_principals_enabled ||
        length(var.additional_assume_role_statements) > 0
      )
      error_message = "At least one IAM trust source must be configured when create_iam_role is true."
    }

    precondition {
      condition     = !var.enable_application_kms_decryption || local.kms_enabled
      error_message = "A created or existing KMS key is required when enable_application_kms_decryption is true."
    }
  }
}

resource "aws_iam_role_policy" "kms_decrypt" {
  count = var.create_iam_role && var.enable_application_kms_decryption ? 1 : 0

  name = "${local.name_prefix}-kms-decrypt"
  role = aws_iam_role.this[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowInvokrKMSDecryption"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = local.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_managed" {
  for_each = var.create_iam_role ? toset(var.aws_managed_policy_names) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_role_policy_attachment" "customer_managed" {
  for_each = var.create_iam_role ? toset(var.customer_managed_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.create_iam_role ? var.inline_policies : {}

  name   = each.key
  role   = aws_iam_role.this[0].name
  policy = each.value
}
