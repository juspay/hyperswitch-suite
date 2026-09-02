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

  # Resolve per-deployment settings, falling back to module-level defaults
  # for any field a deployment doesn't override - same
  # override-or-inherit pattern as the AWS module's deployments map.
  resolved_deployments = {
    for name, d in var.deployments : name => {
      weight       = d.weight
      envoy_image  = coalesce(d.envoy_image, var.envoy_image)
      machine_type = coalesce(d.machine_type, var.machine_type)
      min_replicas = coalesce(d.min_replicas, var.min_replicas)
      max_replicas = coalesce(d.max_replicas, var.max_replicas)
    }
  }

  # Each deployment's envoy_image may be a full self-link
  # (https://www.googleapis.com/compute/v1/projects/P/global/images/I, or
  # projects/P/global/images/I) or a bare image name living in
  # var.project_id. terraform-google-modules/vm's instance_template always
  # builds disk.source_image as "${source_image_project}/${source_image}",
  # defaulting source_image_project to "rocky-linux-cloud" whenever it
  # isn't explicitly set (var.source_image_project != "" ? ... :
  # "rocky-linux-cloud" - passing "" does not opt out, since "" fails that
  # check too) - so a full self-link passed straight through as
  # source_image with source_image_project left at its default silently
  # produces a malformed reference. Confirmed via a live `terraform plan`
  # showing exactly that string for module.proxy_template's
  # disk.source_image before this fix, 2026-08-20 (original single-image
  # version of this logic). Parse both accepted input shapes explicitly
  # here, per deployment, instead of relying on that module's own
  # family/project default.
  deployment_images = {
    for name, d in local.resolved_deployments : name => {
      is_self_link = can(regex("projects/[^/]+/global/images/", d.envoy_image))
      project = can(regex("projects/[^/]+/global/images/", d.envoy_image)) ? regex(
        "projects/([^/]+)/global/images/", d.envoy_image
      )[0] : var.project_id
      name = can(regex("projects/[^/]+/global/images/", d.envoy_image)) ? regex(
        "projects/[^/]+/global/images/([^/]+)$", d.envoy_image
      )[0] : d.envoy_image
    }
  }

  # ---------------------------------------------------------------------
  # URL map path_matchers: one per distinct host set found in
  # var.listener_rules, plus a "default" matcher (hosts = ["*"]) for rules
  # with host = null. GCP's route_rules match on path/header only - host
  # selection happens one level up, via which path_matcher a host_rule
  # points requests at - so rules that need host-scoping get grouped into
  # their own path_matcher rather than being expressed as a match_rules
  # condition.
  #
  # The map key (used as the path_matcher/host_rule name) is derived from
  # an md5 hash of the sorted, comma-joined host list rather than the raw
  # hostnames: GCP resource sub-block names must match
  # [a-z]([-a-z0-9]*[a-z0-9])? and stay under 63 characters, and raw
  # hostnames contain dots and can be arbitrarily long/numerous when a
  # rule lists many hosts.
  # ---------------------------------------------------------------------
  path_matchers = merge(
    {
      default = {
        hosts = ["*"]
        rules = [for r in var.listener_rules : r if r.host == null]
      }
    },
    {
      for host_key, rules in {
        for r in var.listener_rules : join(",", sort(r.host)) => r... if r.host != null
        } : "host-${substr(md5(host_key), 0, 12)}" => {
        hosts = sort(rules[0].host)
        rules = rules
      }
    }
  )
}
