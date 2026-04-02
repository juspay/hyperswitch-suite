locals {
  name_prefix = "${var.environment}-${var.project_name}-${var.app_name}"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Application" = var.app_name
      "Service"     = "OpenTelemetry Collector"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  oidc_enabled                      = length(var.cluster_service_accounts) > 0
  assume_role_principals_enabled    = length(var.assume_role_principals) > 0
  aws_managed_policies_enabled      = length(var.aws_managed_policy_names) > 0
  customer_managed_policies_enabled = length(var.customer_managed_policy_arns) > 0

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
