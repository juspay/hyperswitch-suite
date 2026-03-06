locals {
  name_prefix = "${var.environment}-${var.project_name}-alb"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "load-balancer"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )

  # Determine if ACM certificate should be created
  create_acm_certificate = var.acm != null && var.acm.create_certificate

  # Get the certificate ARN (from created cert or provided)
  certificate_arn = local.create_acm_certificate ? module.acm[0].acm_certificate_arn : var.certificate_arn
}
