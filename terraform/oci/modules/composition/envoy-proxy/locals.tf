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

  # ---------------------------------------------------------------------------
  # NSG membership
  # ---------------------------------------------------------------------------
  # Both NSGs are created empty here and filled by the security-rules unit in
  # the last stack phase. Membership, however, is declared on the CONSUMER
  # resource (create_vnic_details.nsg_ids on the pool's instance configuration,
  # network_security_group_ids on the load balancer) - which is why forgetting
  # to attach is a real failure mode on OCI in a way it is not on AWS. An NSG
  # with perfect rules and no VNICs in it is silently inert; because NSG rules
  # are allow-only, the symptom is a connectivity failure, not an exposure.
  # network-security-model.md section 6 records this as a named risk.
  own_instance_nsg_ids = var.create_nsg ? [oci_core_network_security_group.instances[0].id] : []
  own_lb_nsg_ids       = var.create_nsg ? [oci_core_network_security_group.lb[0].id] : []

  instance_nsg_ids = concat(local.own_instance_nsg_ids, var.additional_nsg_ids)
  lb_nsg_ids       = concat(local.own_lb_nsg_ids, var.additional_lb_nsg_ids)

  # ---------------------------------------------------------------------------
  # Deployments - resolution and sizing
  # ---------------------------------------------------------------------------
  total_weight = sum([for d in values(var.deployments) : d.weight])

  shared_backend_set_mode = var.traffic_split_mode == "shared_backend_set"

  # Highest-weight deployment, used as the cutover default. Sorted by key as a
  # tiebreak so the choice is deterministic across plans.
  default_active_deployment = coalesce(
    var.active_deployment,
    [
      for k in sort(keys(var.deployments)) : k
      if var.deployments[k].weight == max([for d in values(var.deployments) : d.weight]...)
    ][0]
  )

  # Sizing, and this is where var.deployments' `weight` actually lands.
  #
  # shared_backend_set mode: there is no settable per-backend weight (backends
  # are created by the instance pool, and oci_load_balancer_backend_set.backend
  # is a read-only attribute), so traffic share == instance-count share. The
  # fleet floor and ceiling (var.min_replicas / var.max_replicas) are therefore
  # SPLIT across deployments in proportion to weight. ceil() and the max(1, ...)
  # floor mean a small-weight canary always gets at least one instance, which
  # is also the granularity limit: 1 instance out of a 10-instance fleet is 10%,
  # and no finer split than that is expressible.
  #
  # listener_cutover mode: no split at all - each deployment is sized in full,
  # because only one of them is receiving traffic at a time.
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

  # ---------------------------------------------------------------------------
  # Backend sets
  # ---------------------------------------------------------------------------
  # One shared set, or one per deployment. Names are the resource keys.
  backend_set_names = local.shared_backend_set_mode ? ["envoy"] : sort(keys(var.deployments))

  # Which backend set each pool registers itself into.
  pool_backend_set = {
    for key, d in var.deployments : key => local.shared_backend_set_mode ? "envoy" : key
  }

  default_backend_set_name = local.shared_backend_set_mode ? "envoy" : local.default_active_deployment

  load_balancer_id = var.create_lb ? try(oci_load_balancer_load_balancer.this[0].id, null) : var.existing_load_balancer_id

  # When create_lb = false the pools attach to a caller-supplied backend set on
  # a caller-supplied load balancer. Attachment is skipped entirely if either
  # is missing, leaving an unregistered pool rather than a plan-time crash.
  attach_backend_set_name = var.create_lb ? null : var.existing_backend_set_name
  attach_to_lb            = var.create_lb ? true : (var.existing_load_balancer_id != null && var.existing_backend_set_name != null)

  health_check_port = coalesce(var.health_check.port, var.backend_port)

  # ---------------------------------------------------------------------------
  # Autoscaling - the target-tracking -> threshold translation
  # ---------------------------------------------------------------------------
  # See var.scaling_policies for why this exists. Each enabled signal produces
  # TWO rules with a deadband between them; OCI's threshold policy has no
  # controller that converges on a target, so the deadband is the module
  # author's responsibility rather than the service's.
  #
  # metric_source = COMPUTE_AGENT means the value comes from the Oracle Cloud
  # Agent's monitoring plugin on the instance, not from the hypervisor. For
  # CPU_UTILIZATION either source works; MEMORY_UTILIZATION is agent-only,
  # which is the same precondition AWS's CloudWatch-agent-backed memory policy
  # carries. Enabling the memory signal on an image without a working agent
  # produces a silently inert policy on both clouds.
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

  # An autoscaling configuration with a threshold policy and no rules is
  # rejected, and a scheduled-only configuration is legitimate, so attach one
  # only when there is something for it to carry.
  autoscaling_enabled = var.enable_autoscaling && (
    length(local.threshold_rules) > 0 || length(var.scheduled_scaling_policies) > 0
  )

  autoscaled_deployments = local.autoscaling_enabled ? local.deployments : {}

  # ---------------------------------------------------------------------------
  # Instance metadata
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Buckets
  # ---------------------------------------------------------------------------
  # OCI bucket names are unique per namespace per region, NOT globally the way
  # S3's are, so the AWS module's random-suffix dance is unnecessary here.
  config_bucket_name = coalesce(var.config_bucket_name, "${local.name_prefix}-config")
  logs_bucket_name   = coalesce(var.logs_bucket_name, "${local.name_prefix}-logs")

  config_objects = merge(
    var.envoy_config_content != null ? { "envoy.yaml" = var.envoy_config_content } : {},
    var.additional_config_files
  )

  # ---------------------------------------------------------------------------
  # Routing-policy condition generation
  # ---------------------------------------------------------------------------
  # OCI's routing-policy condition language, version V1. See
  # var.listener_rules for the two caveats: no source-IP dimension exists at
  # this layer, and the exact grammar below is documentation-derived rather
  # than confirmed against a live tenancy (check sheet open question 9.1).
  # raw_condition bypasses everything here.
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
