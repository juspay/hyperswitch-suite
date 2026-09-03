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
    var.istio_base
  )
  istiod = merge(
    { release_name = "istiod", chart_repo = "https://istio-release.storage.googleapis.com/charts", chart_version = null, values = [], values_file = "" },
    var.istiod
  )
  istio_gateway = merge(
    { release_name = "istio-gateway", chart_repo = "https://istio-release.storage.googleapis.com/charts", chart_version = null, values = [], values_file = "" },
    var.istio_gateway
  )
}
