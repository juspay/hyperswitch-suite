locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"

  # See var.force_destroy_buckets' own description for the auto-derivation
  # rule and why null falls back to it.
  force_destroy_buckets = var.force_destroy_buckets != null ? var.force_destroy_buckets : var.environment != "prod"

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


  squid_image_is_family_link = can(regex("global/images/family/[^/]+$", var.squid_image))
  squid_image_is_self_link   = can(regex("projects/[^/]+/global/images/", var.squid_image))
  squid_image_project        = local.squid_image_is_self_link ? regex("projects/([^/]+)/global/images/", var.squid_image)[0] : var.project_id
  squid_image_family_name    = local.squid_image_is_family_link ? regex("global/images/family/([^/]+)$", var.squid_image)[0] : null
  squid_image_direct_name = local.squid_image_is_family_link ? null : (
    local.squid_image_is_self_link ? regex("global/images/([^/]+)$", var.squid_image)[0] : var.squid_image
  )
}
