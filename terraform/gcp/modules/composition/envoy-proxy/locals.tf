locals {
  name_prefix = "${var.environment}-${var.project_name}-envoy"

  # Null auto-derives: destroyable everywhere except prod.
  force_destroy_buckets = var.force_destroy_buckets != null ? var.force_destroy_buckets : var.environment != "prod"

  common_labels = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "envoy-proxy"
      "managed_by"  = "terraform"
    },
    var.labels
  )

  # Per-deployment settings, falling back to the module-level defaults for any
  # field a deployment doesn't override.
  resolved_deployments = {
    for name, d in var.deployments : name => {
      weight       = d.weight
      envoy_image  = coalesce(d.envoy_image, var.envoy_image)
      machine_type = coalesce(d.machine_type, var.machine_type)
      min_replicas = coalesce(d.min_replicas, var.min_replicas)
      max_replicas = coalesce(d.max_replicas, var.max_replicas)
    }
  }

  # Split each deployment's envoy_image into project + name. The image may be a
  # full self-link or a bare name in var.project_id; the upstream instance_template
  # module always concatenates "${source_image_project}/${source_image}" and
  # defaults the project to rocky-linux-cloud, so passing a self-link through
  # unparsed produces a malformed reference.
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

  # URL map path_matchers: one per distinct host set in var.listener_rules, plus
  # a "default" matcher (hosts = ["*"]) for rules with host = null. route_rules
  # match on path/header only, so host-scoping is expressed by which
  # path_matcher a host_rule points at.
  #
  # Keys are md5-hashed because path_matcher names must match
  # [a-z]([-a-z0-9]*[a-z0-9])? and stay under 63 characters.
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
