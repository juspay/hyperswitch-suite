locals {
  name_prefix  = "${var.environment}-${var.project_name}-envoy"
  display_name = local.name_prefix

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "envoy-proxy"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  availability_domain = coalesce(
    var.availability_domain,
    data.oci_identity_availability_domains.this.availability_domains[0].name
  )

  namespace = data.oci_objectstorage_namespace.this.namespace

  # Both NSGs are created empty by network.tf and filled by the security-rules
  # unit in the last stack phase. Membership is declared on the CONSUMER
  # resource - an NSG with perfect rules but no VNIC in it is silently inert.
  own_instance_nsg_ids = var.create_nsg ? [oci_core_network_security_group.instances[0].id] : []
  own_lb_nsg_ids       = var.create_nsg ? [oci_core_network_security_group.lb[0].id] : []

  instance_nsg_ids = concat(local.own_instance_nsg_ids, var.additional_nsg_ids)
  lb_nsg_ids       = concat(local.own_lb_nsg_ids, var.additional_lb_nsg_ids)

  total_weight = sum([for d in values(var.deployments) : d.weight])

  shared_backend_set_mode = var.traffic_split_mode == "shared_backend_set"

  # Highest-weight deployment, used as the cutover default; sorted by key for a
  # deterministic tiebreak.
  default_active_deployment = coalesce(
    var.active_deployment,
    [
      for k in sort(keys(var.deployments)) : k
      if var.deployments[k].weight == max([for d in values(var.deployments) : d.weight]...)
    ][0]
  )

  # In shared_backend_set mode traffic share == instance-count share (per-backend
  # weight is not settable), so the fleet floor/ceiling is SPLIT across
  # deployments in proportion to weight, with a max(1, ...) floor so a small
  # canary always gets at least one instance. In listener_cutover mode each
  # deployment is sized in full because only one is receiving traffic at a time.
  deployments = {
    for key, d in var.deployments : key => {
      weight         = d.weight
      image_id       = coalesce(d.image_id, var.image_id)
      shape          = coalesce(d.shape, var.shape)
      ocpus          = coalesce(d.ocpus, var.shape_ocpus)
      memory_in_gbs  = coalesce(d.memory_in_gbs, var.shape_memory_in_gbs)
      is_preemptible = d.is_preemptible

      min_replicas = coalesce(
        d.min_replicas,
        local.shared_backend_set_mode
        ? max(1, ceil(var.min_replicas * d.weight / local.total_weight))
        : var.min_replicas
      )
      max_replicas = coalesce(
        d.max_replicas,
        local.shared_backend_set_mode
        ? max(1, ceil(var.max_replicas * d.weight / local.total_weight))
        : var.max_replicas
      )
    }
  }

  # One shared set, or one per deployment.
  backend_set_names = local.shared_backend_set_mode ? ["envoy"] : sort(keys(var.deployments))

  # Which backend set each pool registers into.
  pool_backend_set = {
    for key, d in var.deployments : key => local.shared_backend_set_mode ? "envoy" : key
  }

  default_backend_set_name = local.shared_backend_set_mode ? "envoy" : local.default_active_deployment

  load_balancer_id = var.create_lb ? try(oci_load_balancer_load_balancer.this[0].id, null) : var.existing_load_balancer_id

  # When create_lb = false the pools attach to a caller-supplied backend set;
  # attachment is skipped if either id is missing, leaving an unregistered pool
  # rather than a plan-time crash.
  attach_backend_set_name = var.create_lb ? null : var.existing_backend_set_name
  attach_to_lb            = var.create_lb ? true : (var.existing_load_balancer_id != null && var.existing_backend_set_name != null)

  health_check_port = coalesce(var.health_check.port, var.backend_port)

  # Each enabled signal produces TWO rules with a deadband between them; OCI's
  # threshold policy has no controller that converges on a target, so the
  # deadband is the module author's responsibility. metric_source
  # COMPUTE_AGENT means the value comes from the monitoring plugin on the
  # instance; MEMORY_UTILIZATION is agent-only, so a memory signal on an image
  # without a working agent is a silently inert policy.
  cpu_policy    = var.scaling_policies.cpu_target_tracking
  memory_policy = var.scaling_policies.memory_target_tracking

  threshold_rules = concat(
    local.cpu_policy.enabled ? [
      {
        display_name     = "scale-out-cpu"
        metric_type      = "CPU_UTILIZATION"
        operator         = "GT"
        value            = local.cpu_policy.target_value
        action_type      = "CHANGE_COUNT_BY"
        action_value     = local.cpu_policy.scale_out_step
        pending_duration = local.cpu_policy.pending_duration
      },
      {
        display_name     = "scale-in-cpu"
        metric_type      = "CPU_UTILIZATION"
        operator         = "LT"
        value            = local.cpu_policy.target_value - local.cpu_policy.scale_in_offset
        action_type      = "CHANGE_COUNT_BY"
        action_value     = -1 * local.cpu_policy.scale_in_step
        pending_duration = local.cpu_policy.pending_duration
      },
    ] : [],
    local.memory_policy.enabled ? [
      {
        display_name     = "scale-out-memory"
        metric_type      = "MEMORY_UTILIZATION"
        operator         = "GT"
        value            = local.memory_policy.target_value
        action_type      = "CHANGE_COUNT_BY"
        action_value     = local.memory_policy.scale_out_step
        pending_duration = local.memory_policy.pending_duration
      },
      {
        display_name     = "scale-in-memory"
        metric_type      = "MEMORY_UTILIZATION"
        operator         = "LT"
        value            = local.memory_policy.target_value - local.memory_policy.scale_in_offset
        action_type      = "CHANGE_COUNT_BY"
        action_value     = -1 * local.memory_policy.scale_in_step
        pending_duration = local.memory_policy.pending_duration
      },
    ] : []
  )

  # A threshold policy with no rules is rejected, and a scheduled-only
  # configuration is legitimate, so attach one only when it carries something.
  autoscaling_enabled = var.enable_autoscaling && (
    length(local.threshold_rules) > 0 || length(var.scheduled_scaling_policies) > 0
  )

  autoscaled_deployments = local.autoscaling_enabled ? local.deployments : {}

  ssh_authorized_keys = join("\n", compact(concat(
    var.generate_ssh_key ? [tls_private_key.break_glass[0].public_key_openssh] : [],
    var.ssh_public_keys
  )))

  base_metadata = merge(
    length(local.ssh_authorized_keys) > 0 ? { ssh_authorized_keys = local.ssh_authorized_keys } : {},
    var.custom_user_data != null ? { user_data = base64encode(var.custom_user_data) } : {},
    {
      config_bucket    = var.create_config_bucket ? local.config_bucket_name : ""
      config_namespace = local.namespace
      envoy_region     = var.region
    }
  )

  instance_metadata = merge(var.metadata, local.base_metadata)

  # Bucket names are unique per namespace per region, not globally as S3's are.
  config_bucket_name = coalesce(var.config_bucket_name, "${local.name_prefix}-config")
  logs_bucket_name   = coalesce(var.logs_bucket_name, "${local.name_prefix}-logs")

  config_objects = merge(
    var.envoy_config_content != null ? { "envoy.yaml" = var.envoy_config_content } : {},
    var.additional_config_files
  )

  # OCI routing-policy condition language, V1; raw_condition bypasses the
  # generator below.
  listener_rule_conditions = {
    for r in var.listener_rules : r.name => (
      r.raw_condition != null
      ? r.raw_condition
      : format("all(%s)", join(", ", compact([
        r.host != null && length(coalesce(r.host, [])) > 0
        ? format("any(%s)", join(", ", [
          for h in r.host : "http.request.headers[(i 'host')] eq (i '${h}')"
        ]))
        : "",
        r.path_prefix != null ? "http.request.url.path sw (i '${r.path_prefix}')" : "",
        r.path_exact != null ? "http.request.url.path eq (i '${r.path_exact}')" : "",
      ])))
    )
  }

  listener_rule_targets = {
    for r in var.listener_rules : r.name => (
      r.target_backend_set != null
      ? r.target_backend_set
      : local.pool_backend_set[r.target_deployment]
    )
  }

  routing_policy_enabled = var.create_lb && length(var.listener_rules) > 0
  routing_policy_name    = "${replace(local.name_prefix, "-", "_")}_rules"

  redirect_rule_set_name = "${replace(local.name_prefix, "-", "_")}_https_redirect"
  http_redirect_enabled  = var.create_lb && var.enable_http_redirect && var.enable_https_listener

  https_listener_enabled = var.create_lb && var.enable_https_listener && length(var.ssl_certificate_ids) > 0
  mtls_listener_enabled  = var.create_lb && var.mtls_listener.enabled

  waf_enabled = var.create_lb && var.enable_waf && var.waf_policy_id != null

  vault_secret_enabled = var.generate_ssh_key && var.vault_id != null && var.vault_key_id != null
}
