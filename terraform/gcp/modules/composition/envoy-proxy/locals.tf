locals {
  name_prefix = "${var.environment}-${var.project_name}-envoy"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "envoy-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # var.envoy_image may be a full self-link
  # (https://www.googleapis.com/compute/v1/projects/P/global/images/I, or
  # projects/P/global/images/I) or a bare image name living in
  # var.project_id. terraform-google-modules/vm's instance_template always
  # builds disk.source_image as "${source_image_project}/${source_image}",
  # defaulting source_image_project to "rocky-linux-cloud" whenever it
  # isn't explicitly set (var.source_image_project != "" ? ... :
  # "rocky-linux-cloud" - passing "" does not opt out, since "" fails that
  # check too) - so a full self-link passed straight through as
  # source_image with source_image_project left at its default silently
  # produces "rocky-linux-cloud/https://.../hyperswitch-envoy-...", a
  # malformed reference. Confirmed via a live `terraform plan` showing
  # exactly that string for module.proxy_template's disk.source_image
  # before this fix, 2026-08-20. Parse both accepted input shapes
  # explicitly here instead of relying on that module's own family/project
  # default.
  # Matches "projects/" wherever it appears (with or without a leading
  # slash / https://.../compute/v1/ prefix) - both the full self-link and
  # the shorter "projects/P/global/images/I" form contain this substring,
  # a bare image name never does.
  envoy_image_is_self_link = can(regex("projects/[^/]+/global/images/", var.envoy_image))
  envoy_image_project      = local.envoy_image_is_self_link ? regex("projects/([^/]+)/global/images/", var.envoy_image)[0] : var.project_id
  envoy_image_name         = local.envoy_image_is_self_link ? regex("projects/[^/]+/global/images/([^/]+)$", var.envoy_image)[0] : var.envoy_image
}
