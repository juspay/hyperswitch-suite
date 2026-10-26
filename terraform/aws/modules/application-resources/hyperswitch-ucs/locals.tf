locals {
  name_prefix = "${var.environment}-${var.project_name}-${var.app_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Application" = var.app_name
      # IAM tag values allow only letters, digits, spaces and _.:/=+-@ — no parentheses.
      "Service"   = "Hyperswitch UCS Unified Connector Service"
      "ManagedBy" = "terraform"
    },
    var.region != null ? { "Region" = var.region } : {},
    var.tags
  )

  # =========================================================================
  # Feature Enablement Flags
  # =========================================================================

  # OIDC/IRSA feature
  oidc_enabled = length(var.cluster_service_accounts) > 0

  # Assume role principals feature
  assume_role_principals_enabled = length(var.assume_role_principals) > 0

  # AWS managed policies feature
  aws_managed_policies_enabled = length(var.aws_managed_policy_names) > 0

  # Customer managed policies feature
  customer_managed_policies_enabled = length(var.customer_managed_policy_arns) > 0

  # Inline policies feature
  inline_policies_enabled = length(var.inline_policies) > 0

  # Secrets Manager feature
  secrets_manager_enabled = try(var.secrets_manager.enabled, false) && length(try(var.secrets_manager.secret_arns, [])) > 0
  secrets_manager_arns    = local.secrets_manager_enabled ? var.secrets_manager.secret_arns : []

  # =========================================================================
  # OIDC Configuration
  # =========================================================================
  cluster_oidc_statements = {
    for cluster_name, service_accounts in var.cluster_service_accounts : cluster_name => {
      oidc_arn = data.aws_iam_openid_connect_provider.oidc[cluster_name].arn
      oidc_url = data.aws_iam_openid_connect_provider.oidc[cluster_name].url
      subjects = [
        for sa in service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"
      ]
    }
  }
}
