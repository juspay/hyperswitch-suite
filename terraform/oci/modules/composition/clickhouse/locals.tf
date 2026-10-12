locals {
  name_prefix = "${var.environment}-${var.project_name}-clickhouse"

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "clickhouse"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  # ---------------------------------------------------------------------------
  # Placement
  # ---------------------------------------------------------------------------
  availability_domain = coalesce(
    var.availability_domain,
    try(data.oci_identity_availability_domains.this[0].availability_domains[0].name, null)
  )

  fault_domains = length(var.fault_domains) > 0 ? var.fault_domains : [
    for fd in try(data.oci_identity_fault_domains.this[0].fault_domains, []) : fd.name
  ]

  fault_domain_count = length(local.fault_domains)

  # Keepers and servers are offset from one another so a 3-Keeper + 2-server
  # deployment does not stack keeper-0 and server-0 in the same fault domain.
  keeper_fault_domain = [
    for i in range(var.keeper_count) :
    local.fault_domain_count > 0 ? local.fault_domains[i % local.fault_domain_count] : null
  ]

  server_fault_domain = [
    for i in range(var.server_count) :
    local.fault_domain_count > 0 ? local.fault_domains[(i + 1) % local.fault_domain_count] : null
  ]

  # ---------------------------------------------------------------------------
  # NSG membership
  # ---------------------------------------------------------------------------
  keeper_nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.keeper[0].id] : [],
    var.additional_keeper_nsg_ids
  ))

  server_nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.server[0].id] : [],
    var.additional_server_nsg_ids
  ))

  # ---------------------------------------------------------------------------
  # SSH key pair - OCI has no key-pair object, only instance metadata
  # ---------------------------------------------------------------------------
  key_pair_name = coalesce(var.key_name, "${local.name_prefix}-key")

  generate_key = var.create_key_pair && var.public_key == null

  public_key = var.create_key_pair ? (
    local.generate_key ? tls_private_key.clickhouse[0].public_key_openssh : var.public_key
  ) : null

  vault_secret_create = (
    local.generate_key
    && var.vault_secret != null
    && try(var.vault_secret.vault_id, null) != null
    && try(var.vault_secret.key_id, null) != null
  )

  vault_secret_name = coalesce(try(var.vault_secret.secret_name, null), "${local.name_prefix}-ssh-private-key")

  # ---------------------------------------------------------------------------
  # Peer address lists and the {{keeper_ips}} / {{server_ips}} substitution
  # ---------------------------------------------------------------------------
  # THE SAME CYCLE CONSTRAINT AS ../cassandra/locals.tf, and here it bites harder
  # because BOTH tiers' user data names BOTH tiers' peers.
  #
  # A reserved private IP is created ON a VNIC, and the VNIC only exists once its
  # instance does, so oci_core_private_ip depends on oci_core_instance. Anything
  # an instance's own user_data reads therefore cannot come from
  # oci_core_private_ip. AWS had no such problem: its ENIs are created BEFORE the
  # instances and hand their IPs over at plan time, which is exactly why the AWS
  # module can substitute {{keeper_ips}} from aws_network_interface outputs.
  #
  # Consequence: PIN keeper_reserved_ip_addresses AND server_reserved_ip_addresses.
  # Left unpinned, the templates below are rendered with empty peer lists and the
  # cluster will not form - the module still plans and applies cleanly, which is
  # the dangerous part. There is no way to make this fail at plan time without
  # forbidding the unpinned case outright, which would break the "let OCI
  # allocate" path some environments legitimately want for a single-node dev cut.
  keeper_pinned_ips = var.keeper_reserved_ip_addresses != null ? compact(var.keeper_reserved_ip_addresses) : []
  server_pinned_ips = var.server_reserved_ip_addresses != null ? compact(var.server_reserved_ip_addresses) : []

  keeper_ips_string = join(",", local.keeper_pinned_ips)
  server_ips_string = join(",", local.server_pinned_ips)

  keeper_ip_addresses = [
    for i in range(var.keeper_count) :
    try(var.keeper_reserved_ip_addresses[i], null)
  ]

  server_ip_addresses = [
    for i in range(var.server_count) :
    try(var.server_reserved_ip_addresses[i], null)
  ]

  # Resolved from the created objects. OUTPUTS ONLY - never anything an instance
  # depends on, per the cycle note above.
  keeper_reserved_ips = oci_core_private_ip.keeper[*].ip_address
  server_reserved_ips = oci_core_private_ip.server[*].ip_address

  # ---------------------------------------------------------------------------
  # Bootstrap payloads
  # ---------------------------------------------------------------------------
  # Same template-substitution mechanism as the AWS module, unchanged - the
  # software-facing contract does not change across clouds. Only the envelope
  # differs (metadata.user_data, base64, OCI IMDS v2).
  keeper_user_data = var.keeper_user_data_template == null ? null : replace(
    replace(var.keeper_user_data_template, "{{keeper_ips}}", local.keeper_ips_string),
    "{{server_ips}}", local.server_ips_string
  )

  server_user_data = var.server_user_data_template == null ? null : replace(
    replace(var.server_user_data_template, "{{keeper_ips}}", local.keeper_ips_string),
    "{{server_ips}}", local.server_ips_string
  )

  keeper_metadata = merge(
    local.keeper_user_data != null ? { user_data = base64encode(local.keeper_user_data) } : {},
    local.public_key != null ? { ssh_authorized_keys = local.public_key } : {}
  )

  server_metadata = merge(
    local.server_user_data != null ? { user_data = base64encode(local.server_user_data) } : {},
    local.public_key != null ? { ssh_authorized_keys = local.public_key } : {}
  )

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  create_identity = var.create_identity && var.tenancy_ocid != null

  matching_rule = coalesce(
    var.identity_matching_rule,
    "ALL {instance.compartment.id = '${var.compartment_id}'}"
  )

  default_policy_statements = [
    "Allow dynamic-group ${local.name_prefix}-nodes to inspect instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to read instance-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to use log-content in compartment id ${var.compartment_id}",
  ]

  policy_statements = length(var.policy_statements) > 0 ? var.policy_statements : local.default_policy_statements

  # ---------------------------------------------------------------------------
  # Load balancer
  # ---------------------------------------------------------------------------
  backend_set_name = "${replace(local.name_prefix, "-", "_")}_servers"

  # Defaults to a single HTTP listener on clickhouse_port when the caller
  # supplies none, matching the AWS module's behaviour.
  listeners = length(var.load_balancer_listeners) > 0 ? var.load_balancer_listeners : [
    {
      name           = "http"
      port           = var.clickhouse_port
      protocol       = "HTTP"
      certificate_id = null
    },
  ]

  agent_plugins = [
    {
      name          = "Compute Instance Monitoring"
      desired_state = var.enable_monitoring_plugin ? "ENABLED" : "DISABLED"
    },
  ]
}
