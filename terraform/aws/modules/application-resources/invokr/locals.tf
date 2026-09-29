locals {
  name_prefix = "${var.environment}-${var.project_name}-${var.app_name}"
  region      = var.region != null ? var.region : data.aws_region.current.region

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      Application = var.app_name
      Component   = "Invokr"
      Service     = "Invokr Application"
      ManagedBy   = "terraform"
      Region      = local.region
    },
    var.tags
  )

  kms_enabled = var.kms.create || var.kms.key_arn != null
  kms_key_arn = var.kms.create ? module.kms[0].key_arn : (
    var.kms.key_arn != null ? data.aws_kms_key.existing[0].arn : null
  )
  kms_key_id = var.kms.create ? module.kms[0].key_id : (
    var.kms.key_arn != null ? data.aws_kms_key.existing[0].key_id : null
  )

  oidc_enabled = length(var.cluster_service_accounts) > 0
  cluster_oidc_statements = {
    for cluster_name, cluster in var.cluster_service_accounts : cluster_name => {
      oidc_arn = cluster.oidc_provider_arn
      oidc_url = split(":oidc-provider/", cluster.oidc_provider_arn)[1]
      subjects = [
        for service_account in cluster.service_accounts :
        "system:serviceaccount:${service_account.namespace}:${service_account.name}"
      ]
    }
  }

  assume_role_principals_enabled = length(var.assume_role_principals) > 0
  application_secret_enabled     = var.create_application_secret || var.existing_application_secret_arn != null
}
