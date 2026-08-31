locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "squid-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # terraform-google-modules/lb-internal requires bare network/subnetwork
  # NAMES, not self-links - passing var.network/var.lb_subnetwork straight
  # through fails with "Invalid value for field 'network'" (confirmed via a
  # live apply, 2026-08-24). Strip both down to their last path segment.
  internal_lb_network_name = element(split("/", var.network), length(split("/", var.network)) - 1)
  internal_lb_subnet_name  = element(split("/", var.lb_subnetwork), length(split("/", var.lb_subnetwork)) - 1)
}
