locals {
  name_prefix  = "${var.environment}-${var.project_name}-squid"
  display_name = local.name_prefix

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "squid-proxy"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  availability_domain = coalesce(
    var.availability_domain,
    data.oci_identity_availability_domains.this.availability_domains[0].name
  )

  namespace = data.oci_objectstorage_namespace.this.namespace

  nlb_subnet_id = coalesce(var.nlb_subnet_id, var.subnet_id)

  # NSG membership is declared on the CONSUMER resource, not on the NSG.
  own_instance_nsg_ids = var.create_nsg ? [oci_core_network_security_group.instances[0].id] : []
  own_nlb_nsg_ids      = var.create_nsg ? [oci_core_network_security_group.nlb[0].id] : []

  instance_nsg_ids = concat(local.own_instance_nsg_ids, var.additional_nsg_ids)
  nlb_nsg_ids      = concat(local.own_nlb_nsg_ids, var.additional_nlb_nsg_ids)

  backend_set_name  = "squid"
  health_check_port = coalesce(var.health_check.port, var.squid_port)

  # ANSWERED (2026-11-17, sandbox us-phoenix-1 first apply): the pool service
  # does NOT accept this module's Network Load Balancer in
  # oci_core_instance_pool.load_balancers. CreateInstancePool failed with
  # 404-NotAuthorizedOrNotFound - the pool service resolves the OCID against
  # the CLASSIC Load Balancer API, where an NLB OCID is not a visible
  # resource, so no IAM policy can fix it. The attach is gated behind
  # var.attach_pool_to_nlb (default false); NLB backend membership is kept
  # correct by scripted per-instance registration (`oci nlb backend create`)
  # outside Terraform, and autoscaler-created instances stay unregistered
  # until that script runs.
  attach_to_lb = var.create_nlb ? var.attach_pool_to_nlb : (
    var.existing_load_balancer_id != null && var.existing_backend_set_name != null
  )

  pool_load_balancer_id = var.create_nlb ? try(oci_network_load_balancer_network_load_balancer.this[0].id, null) : var.existing_load_balancer_id
  pool_backend_set_name = var.create_nlb ? local.backend_set_name : var.existing_backend_set_name

  # Same threshold translation as envoy-proxy's, kept identical on purpose.
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

  autoscaling_enabled = var.enable_autoscaling && (
    length(local.threshold_rules) > 0 || length(var.scheduled_scaling_policies) > 0
  )

  ssh_authorized_keys = join("\n", compact(concat(
    var.generate_ssh_key ? [tls_private_key.break_glass[0].public_key_openssh] : [],
    var.ssh_public_keys
  )))

  base_metadata = merge(
    length(local.ssh_authorized_keys) > 0 ? { ssh_authorized_keys = local.ssh_authorized_keys } : {},
    var.custom_user_data != null ? { user_data = base64encode(var.custom_user_data) } : {},
    {
      # The image's boot script and 15-minute refresh timer read these off the
      # metadata service, which is what lets one image serve every environment.
      # Keep the key names in sync with the image's scripts - a rename silently
      # breaks the allowlist hot reload.
      config_bucket          = var.create_config_bucket ? local.config_bucket_name : ""
      config_namespace       = local.namespace
      squid_config_object    = var.config_object_name
      squid_allowlist_object = var.allowlist_object_name
      squid_port             = tostring(var.squid_port)
    }
  )

  instance_metadata = merge(var.metadata, local.base_metadata)

  config_bucket_name = coalesce(var.config_bucket_name, "${local.name_prefix}-config")
  logs_bucket_name   = coalesce(var.logs_bucket_name, "${local.name_prefix}-logs")

  config_objects = merge(
    var.squid_config_content != null ? { (var.config_object_name) = var.squid_config_content } : {},
    var.squid_allowlist_content != null ? { (var.allowlist_object_name) = var.squid_allowlist_content } : {},
    var.additional_config_files
  )

  vault_secret_enabled = var.generate_ssh_key && var.vault_id != null && var.vault_key_id != null

  # Computed so the output states plainly whether anything terminates TLS, rather
  # than leaving a reader to infer it from the absence of a resource.
  tls_terminated_at = var.tls_termination_mode == "instance" ? "squid-instance" : "nowhere"
}
