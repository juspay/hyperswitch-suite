locals {
  name_prefix = "${var.environment}-${var.project_name}-opensearch"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "opensearch"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Domain name with fallback
  domain_name = var.domain_name != null ? var.domain_name : "${var.environment}-${var.project_name}"

  # Security group name
  security_group_name = var.create_security_group ? (var.security_group_name != null ? var.security_group_name : "${local.name_prefix}-sg") : null
}
