locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"

  # GCS bucket names are global: the same name in two projects collides, so default names carry a
  # suffix (var.bucket_name_suffix; null = first 6 hex of sha256(project_id), "" = none). Names are
  # capped at 63 characters by trimming only the readable prefix - the role and the suffix always
  # survive, so two buckets of one module can never trim to the same name - and a trailing -/_/.
  # is stripped because bucket names must end with a letter or digit.
  bucket_suffix     = var.bucket_name_suffix != null ? var.bucket_name_suffix : substr(sha256(var.project_id), 0, 6)
  bucket_suffix_sep = local.bucket_suffix == "" ? "" : "-${local.bucket_suffix}"
  bucket_names = {
    for role in ["config", "logs"] : role => "${trim(substr(local.name_prefix, 0, 63 - length(role) - 1 - length(local.bucket_suffix_sep)), "-_.")}-${role}${local.bucket_suffix_sep}"
  }

  # Null auto-derives: destroyable everywhere except prod.
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

  # lb-internal requires bare network/subnetwork names, not self-links, so strip
  # both down to their last path segment.
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
