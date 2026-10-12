locals {
  name_prefix = "${var.environment}-${var.project_name}-cassandra"

  freeform_tags = merge(
    {
      environment            = var.environment
      project                = var.project_name
      component              = "cassandra"
      managed_by             = "terraform"
      (var.cluster_tag_name) = var.cluster_tag_value
    },
    var.freeform_tags
  )

  # Placement
  availability_domain = coalesce(
    var.availability_domain,
    try(data.oci_identity_availability_domains.this[0].availability_domains[0].name, null)
  )

  fault_domains = length(var.fault_domains) > 0 ? var.fault_domains : [
    for fd in try(data.oci_identity_fault_domains.this[0].fault_domains, []) : fd.name
  ]

  fault_domain_count = length(local.fault_domains)

  node_fault_domain = [
    for i in range(var.node_count) :
    local.fault_domain_count > 0 ? local.fault_domains[i % local.fault_domain_count] : null
  ]

  # NSG membership
  nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.cassandra[0].id] : [],
    var.additional_nsg_ids
  ))

  # SSH key pair
  key_pair_name = coalesce(var.key_name, "${local.name_prefix}-key")

  generate_key = var.create_key_pair && var.public_key == null

  public_key = var.create_key_pair ? (
    local.generate_key ? tls_private_key.cassandra[0].public_key_openssh : var.public_key
  ) : null

  vault_secret_create = (
    local.generate_key
    && var.vault_secret != null
    && try(var.vault_secret.vault_id, null) != null
    && try(var.vault_secret.key_id, null) != null
  )

  vault_secret_name = coalesce(try(var.vault_secret.secret_name, null), "${local.name_prefix}-ssh-private-key")

  # Reserved private IPs and the seed list
  node_ip_addresses = [
    for i in range(var.node_count) :
    try(var.reserved_ip_addresses[i], null)
  ]

  # ORDER OF EVALUATION MATTERS: the reserved IP is created ON a VNIC, which
  # only exists after the instance - so oci_core_private_ip depends on the
  # instance. Anything the instance's own user_data reads therefore cannot come
  # from oci_core_private_ip without a dependency cycle. Static seed injection
  # works ONLY when the caller pins addresses via var.reserved_ip_addresses;
  # unpinned, the seed list is empty and bootstrap must discover peers another
  # way. Pin the addresses.
  seed_ip_addresses = var.reserved_ip_addresses != null ? compact(var.reserved_ip_addresses) : []

  static_seeds = join(",", local.seed_ip_addresses)

  # Resolved from the created objects. Safe to read in OUTPUTS only - never in
  # anything an instance depends on (see the cycle note above).
  reserved_ips = oci_core_private_ip.node[*].ip_address

  seed_discovery_url = local.seed_discovery_enabled ? "${try(oci_apigateway_deployment.seed_discovery[0].endpoint, "")}${var.seed_discovery_path}" : null

  # seeds_url keeps the AWS output's name; its VALUE changes shape by default - a plain
  # comma-separated list rather than an HTTP endpoint unless discovery is enabled.
  seeds_url_value = try(
    coalesce(
      var.seeds_url,
      local.seed_discovery_url,
      join(",", local.reserved_ips)
    ),
    ""
  )

  # Bootstrap payload.
  default_user_data = jsonencode({
    clusterName       = var.cluster_name
    replicationFactor = var.replication_factor
    idleTimeout       = var.idle_timeout
    defaultConfigPath = var.default_config_path
    configProfile     = var.config_profile
    seeds             = local.static_seeds
    # coalesce() errors when every argument is null or empty, and both of these
    # legitimately are on the default (static-injection, no discovery) path.
    seedsUrl = try(coalesce(var.seeds_url, local.seed_discovery_url), "")
    ports    = var.cassandra_ports
  })

  user_data = coalesce(var.user_data_override, local.default_user_data)

  instance_metadata = merge(
    { user_data = base64encode(local.user_data) },
    local.public_key != null ? { ssh_authorized_keys = local.public_key } : {}
  )

  # Identity
  create_identity = var.create_identity && var.tenancy_ocid != null

  matching_rule = coalesce(
    var.identity_matching_rule,
    "ALL {instance.compartment.id = '${var.compartment_id}'}"
  )

  # Narrow by default: only read and log write are reproduced; instance-terminate
  # is granted explicitly rather than by default.
  default_policy_statements = [
    "Allow dynamic-group ${local.name_prefix}-nodes to inspect instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to read instance-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to use log-content in compartment id ${var.compartment_id}",
  ]

  policy_statements = length(var.policy_statements) > 0 ? var.policy_statements : local.default_policy_statements

  # Seed discovery
  seed_discovery_enabled = var.enable_seed_discovery && var.seeds_url == null

  agent_plugins = [
    {
      name          = "Compute Instance Monitoring"
      desired_state = var.enable_monitoring_plugin ? "ENABLED" : "DISABLED"
    },
  ]
}
