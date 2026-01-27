# =============================================================================
# Customer Managed Policies
# =============================================================================

resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.value.name
  description = each.value.description
  policy      = each.value.policy
  path        = each.value.path

  tags = merge(var.tags, each.value.tags)
}

# Map policy names to ARNs for easy reference
locals {
  policy_arns_map = {
    for key, policy in aws_iam_policy.this : policy.name => policy.arn
  }
}

# =============================================================================
# IAM Roles
# =============================================================================

locals {
  # Merge default tags with role-specific tags
  role_tags = {
    for key, role in var.roles : key => merge(
      var.tags,
      role.tags
    )
  }
}

# Generate trust policies for each role
locals {
  trust_policies = {
    for key, role in var.roles : key => {
      Version = "2012-10-17"
      Statement = concat(
        # OIDC provider statements
        [
          for provider_key, provider in role.trust_policy.oidc_providers : {
            Effect = "Allow"
            Principal = {
              Federated = provider.provider_arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                # Extract the issuer URL from the provider ARN
                # Format: arn:aws:iam::<account-id>:oidc-provider/<issuer-url>
                "${replace(provider.provider_arn, "arn:aws:iam::[0-9]+:oidc-provider/", "")}:sub" = [
                  for sa in provider.namespace_service_accounts : "system:serviceaccount:${sa}"
                ]
              }
            }
          }
        ],
        # Cross-account assume role statements (only if identifiers are not empty)
        [
          for principal in role.trust_policy.assume_role_principals : {
            Effect = "Allow"
            Principal = {
              "${principal.type}" = principal.identifiers
            }
            Action = "sts:AssumeRole"
          }
          if length(principal.identifiers) > 0
        ]
      )
    }
  }
}

# Create IAM roles
resource "aws_iam_role" "this" {
  for_each = var.roles

  name                  = each.value.role_name
  description           = each.value.description
  path                  = each.value.path
  max_session_duration  = each.value.max_session_duration
  assume_role_policy    = jsonencode(local.trust_policies[each.key])
  force_detach_policies = true

  tags = local.role_tags[each.key]
}

# =============================================================================
# Policy Attachments
# =============================================================================

# Resolve all managed policy ARNs (names + direct ARNs)
locals {
  role_managed_policy_arns = {
    for role_key, role in var.roles : role_key => concat(
      # Resolve policy names to ARNs
      [for name in role.managed_policy_names : local.policy_arns_map[name]],
      # Direct ARNs
      role.managed_policy_arns
    )
  }
}

# Attach managed policies to roles
locals {
  managed_policy_attachments = flatten([
    for role_key, arns in local.role_managed_policy_arns : [
      for idx, arn in arns : {
        key        = "${role_key}-${idx}"
        role_key   = role_key
        policy_arn = arn
      }
    ]
  ])
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for item in local.managed_policy_attachments : item.key => item
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# =============================================================================
# Inline Policies
# =============================================================================

# Create inline policies for roles
locals {
  inline_policy_attachments = flatten([
    for role_key, role in var.roles : [
      for policy_key, policy in role.inline_policies : {
        key        = "${role_key}-${policy_key}"
        role_key   = role_key
        policy_key = policy_key
        policy     = policy
      }
    ]
  ])
}

resource "aws_iam_role_policy" "inline" {
  for_each = {
    for item in local.inline_policy_attachments : item.key => item
  }

  name   = each.value.policy_key
  role   = aws_iam_role.this[each.value.role_key].name
  policy = each.value.policy
}