# ============================================================================
# Local Values
# ============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}-external-secrets"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Application = "external-secrets-operator"
      ManagedBy   = "terraform"
    },
    var.common_tags
  )

  # Group service accounts by cluster and transform to full subject format
  cluster_oidc_statements = {
    for cluster_name, service_accounts in var.cluster_service_accounts : cluster_name => {
      oidc_arn = data.aws_iam_openid_connect_provider.oidc[cluster_name].arn
      oidc_url = data.aws_iam_openid_connect_provider.oidc[cluster_name].url
      # Transform each service account into "system:serviceaccount:namespace:name" format
      subjects = [
        for sa in service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"
      ]
    }
  }
}
