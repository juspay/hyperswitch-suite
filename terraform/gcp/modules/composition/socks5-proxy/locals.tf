locals {
  name_prefix = "${var.environment}-${var.project_name}-socks5"

  # Null auto-derives: destroyable everywhere except prod.
  force_destroy_buckets = var.force_destroy_buckets != null ? var.force_destroy_buckets : var.environment != "prod"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "socks5-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # lb-internal requires bare network/subnetwork names, not self-links, so strip
  # both down to their last path segment.
  internal_lb_network_name = element(split("/", var.network), length(split("/", var.network)) - 1)
  internal_lb_subnet_name  = element(split("/", var.lb_subnetwork), length(split("/", var.lb_subnetwork)) - 1)

  # Accept a bare name, a full image self-link, or a family link - same three
  # forms composition/squid-proxy accepts, so the live layer can pass
  # "family/<name>" and have it work.
  socks5_image_is_family_link = can(regex("global/images/family/[^/]+$", var.socks5_image))
  socks5_image_is_self_link   = can(regex("projects/[^/]+/global/images/", var.socks5_image))
  socks5_image_project        = local.socks5_image_is_self_link ? regex("projects/([^/]+)/global/images/", var.socks5_image)[0] : var.project_id
  socks5_image_family_name    = local.socks5_image_is_family_link ? regex("global/images/family/([^/]+)$", var.socks5_image)[0] : null
  socks5_image_direct_name = local.socks5_image_is_family_link ? null : (
    local.socks5_image_is_self_link ? regex("global/images/([^/]+)$", var.socks5_image)[0] : var.socks5_image
  )
}
