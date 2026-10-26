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
    for cluster_name, cluster in var.cluster_service_accounts : cluster_name => {
      oidc_arn = cluster.oidc_provider_arn
      oidc_url = split(":oidc-provider/", cluster.oidc_provider_arn)[1]
      # Transform each service account into "system:serviceaccount:namespace:name" format
      subjects = [
        for sa in cluster.service_accounts : "system:serviceaccount:${sa.namespace}:${sa.name}"
      ]
    }
  }
}
