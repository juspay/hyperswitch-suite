locals {
  name_prefix = "${var.environment}-${var.project_name}-istio"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "application" = "istio"
    },
    var.labels
  )

  istio_base = merge(
    { release_name = "istio-base", chart_repo = "https://istio-release.storage.googleapis.com/charts", chart_version = null, values = [], values_file = "" },
    try({ for k, v in var.istio_base : k => v if v != null }, {})
  )
  istiod = merge(
    { release_name = "istiod", chart_repo = "https://istio-release.storage.googleapis.com/charts", chart_version = null, values = [], values_file = "" },
    try({ for k, v in var.istiod : k => v if v != null }, {})
  )
  istio_gateway = merge(
    { release_name = "istio-gateway", chart_repo = "https://istio-release.storage.googleapis.com/charts", chart_version = null, values = [], values_file = "" },
    try({ for k, v in var.istio_gateway : k => v if v != null }, {})
  )
}
