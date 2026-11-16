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

  # ---------------------------------------------------------------------------
  # NSG membership
  # ---------------------------------------------------------------------------
  # Declared on the CONSUMER resource, not on the NSG. See network.tf.
  own_instance_nsg_ids = var.create_nsg ? [oci_core_network_security_group.instances[0].id] : []
  own_nlb_nsg_ids      = var.create_nsg ? [oci_core_network_security_group.nlb[0].id] : []

  instance_nsg_ids = concat(local.own_instance_nsg_ids, var.additional_nsg_ids)
  nlb_nsg_ids      = concat(local.own_nlb_nsg_ids, var.additional_nlb_nsg_ids)

  # ---------------------------------------------------------------------------
  # Load balancer wiring
  # ---------------------------------------------------------------------------
  backend_set_name  = "squid"
  health_check_port = coalesce(var.health_check.port, var.squid_port)

  attach_to_lb = var.create_nlb ? true : (
    var.existing_load_balancer_id != null && var.existing_backend_set_name != null
  )

  # OPEN QUESTION, and the module behaves conservatively because of it
  # (check sheet §9 item 1, repeated in vm-tier-and-images.md §7 item 4).
  #
  # oci_core_instance_pool.load_balancers is confirmed to auto-register pool
  # members against a CLASSIC Load Balancer's backend set. Whether it accepts a
  # NETWORK Load Balancer's backend set is NOT confirmed - the schema's own
  # example only shows the classic product, and the field is named
  # load_balancer_id with no NLB-specific variant.
  #
  # This module wires it anyway, because if it works it is the only mechanism
  # that keeps backend membership correct as the pool autoscales. If the apply
  # rejects it, the fallback is per-instance oci_network_load_balancer_backend
  # registration scripted against pool membership - which is real, non-trivial
  # glue code, cannot be expressed declaratively (pool instances are not
  # individual Terraform resources), and would have to run on every scaling
  # event, not just on apply. That fallback is NOT implemented here; discovering
  # which branch is true is a rung-4/rung-6 finding, not something this module
  # can settle statically.
  pool_load_balancer_id = var.create_nlb ? try(oci_network_load_balancer_network_load_balancer.this[0].id, null) : var.existing_load_balancer_id
  pool_backend_set_name = var.create_nlb ? local.backend_set_name : var.existing_backend_set_name

  # ---------------------------------------------------------------------------
  # Autoscaling - the target-tracking -> threshold translation
  # ---------------------------------------------------------------------------
  # Kept byte-for-byte equivalent to envoy-proxy/locals.tf's version on purpose:
  # both modules hit the identical redesign, and vm-tier-and-images.md §3 says
  # it should be solved once, not per-module. If a shared base/vm-pool module
  # is ever approved by the gate (that document's §5/§6), this block and its
  # envoy twin are the first thing to move into it.
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
      # The image's boot script and its 15-minute refresh timer read these off
      # the metadata service rather than having the bucket baked in, which is
      # what lets one image serve every environment. Keep the key names in
      # sync with the image's scripts - a rename here silently breaks the
      # allowlist hot reload.
      config_bucket          = var.create_config_bucket ? local.config_bucket_name : ""
      config_namespace       = local.namespace
      squid_config_object    = var.config_object_name
      squid_allowlist_object = var.allowlist_object_name
      squid_port             = tostring(var.squid_port)
    }
  )

  instance_metadata = merge(var.metadata, local.base_metadata)

  # ---------------------------------------------------------------------------
  # Buckets
  # ---------------------------------------------------------------------------
  config_bucket_name = coalesce(var.config_bucket_name, "${local.name_prefix}-config")
  logs_bucket_name   = coalesce(var.logs_bucket_name, "${local.name_prefix}-logs")

  config_objects = merge(
    var.squid_config_content != null ? { (var.config_object_name) = var.squid_config_content } : {},
    var.squid_allowlist_content != null ? { (var.allowlist_object_name) = var.squid_allowlist_content } : {},
    var.additional_config_files
  )

  vault_secret_enabled = var.generate_ssh_key && var.vault_id != null && var.vault_key_id != null

  # NONE - check sheet feature 3. Recorded as a computed fact so the output can
  # state plainly whether anything is terminating TLS, rather than leaving a
  # reader to infer it from the absence of a resource.
  tls_terminated_at = var.tls_termination_mode == "instance" ? "squid-instance" : "nowhere"
}
