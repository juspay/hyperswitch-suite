# ============================================================================
# Local Variables
# ============================================================================

locals {
  name_prefix = "${var.environment}-${var.project_name}-istio"

  default_values = {
    chart_repo = "https://istio-release.storage.googleapis.com/charts"
    chart_version = "1.28.0"
  }

  istio_base = {
    enabled      = var.istio_base.enabled && var.create_helm_releases
    release_name = var.istio_base.release_name != null ? var.istio_base.release_name : "istio-base"
    chart_repo   = var.istio_base.chart_repo != null ? var.istio_base.chart_repo : local.default_values.chart_repo
    chart_version = var.istio_base.chart_version != null ? var.istio_base.chart_version : local.default_values.chart_version
    values       = var.istio_base.values
    values_file  = var.istio_base.values_file
  }

  istiod = {
    enabled      = var.istiod.enabled && var.create_helm_releases
    release_name = var.istiod.release_name != null ? var.istiod.release_name : "istiod"
    chart_repo   = var.istiod.chart_repo != null ? var.istiod.chart_repo : local.default_values.chart_repo
    chart_version = var.istiod.chart_version != null ? var.istiod.chart_version : local.default_values.chart_version
    values       = var.istiod.values
    values_file  = var.istiod.values_file
  }

  istio_gateway = {
    enabled      = var.istio_gateway.enabled && var.create_helm_releases
    release_name = var.istio_gateway.release_name != null ? var.istio_gateway.release_name : "istio-gateway"
    chart_repo   = var.istio_gateway.chart_repo != null ? var.istio_gateway.chart_repo : local.default_values.chart_repo
    chart_version = var.istio_gateway.chart_version != null ? var.istio_gateway.chart_version : local.default_values.chart_version
    values       = var.istio_gateway.values
    values_file  = var.istio_gateway.values_file
  }

  ingress_annotations = merge(
    var.create_lb_security_group || length(var.lb_security_groups) > 0 ? {
      "alb.ingress.kubernetes.io/security-groups" = var.create_lb_security_group ? join(",", concat([aws_security_group.lb_security_group[0].id], var.lb_security_groups)) : join(",", var.lb_security_groups)
    } : {},
    length(var.lb_subnet_ids) > 0 ? {
      "alb.ingress.kubernetes.io/subnets" = join(",", var.lb_subnet_ids)
    } : {}
  )

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "istio"
      "ManagedBy"   = "terraform"
    },
    var.common_tags
  )

}
