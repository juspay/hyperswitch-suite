locals {
  name_prefix = "${var.environment}-${var.project_name}-kafka"

  # OCI freeform tags are the AWS `tags` / tags_all analogue. Keys are lowercase
  # to match the sibling OCI modules in this wave (database, oci-cache-valkey);
  # the AWS module used TitleCase, which OCI's own convention does not.
  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = var.identity_tag_value
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

  # Round-robin. Brokers and controllers are offset from one another so that a
  # 3-broker + 3-controller cluster puts exactly one of each role in each fault
  # domain rather than stacking broker-0 and controller-0 together.
  broker_fault_domain = [
    for i in range(var.broker_count) :
    local.fault_domain_count > 0 ? local.fault_domains[i % local.fault_domain_count] : null
  ]

  controller_fault_domain = [
    for i in range(var.controller_count) :
    local.fault_domain_count > 0 ? local.fault_domains[i % local.fault_domain_count] : null
  ]

  # ---------------------------------------------------------------------------
  # NSG membership
  # ---------------------------------------------------------------------------
  broker_nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.broker[0].id] : [],
    var.additional_broker_nsg_ids
  ))

  controller_nsg_ids = compact(concat(
    var.create_nsg ? [oci_core_network_security_group.controller[0].id] : [],
    var.additional_controller_nsg_ids
  ))

  # ---------------------------------------------------------------------------
  # SSH key pair
  # ---------------------------------------------------------------------------
  # OCI has no aws_key_pair object at all. A key is not a cloud resource here,
  # it is a line in instance metadata (`ssh_authorized_keys`), so key_name is a
  # label the module carries for output-contract compatibility and nothing else.
  key_pair_name = coalesce(var.key_name, "${local.name_prefix}-key")

  generate_key = var.create_key_pair && var.public_key == null

  public_key = var.create_key_pair ? (
    local.generate_key ? tls_private_key.kafka[0].public_key_openssh : var.public_key
  ) : null

  vault_secret_create = (
    local.generate_key
    && var.vault_secret != null
    && try(var.vault_secret.vault_id, null) != null
    && try(var.vault_secret.key_id, null) != null
  )

  vault_secret_name = coalesce(try(var.vault_secret.secret_name, null), "${local.name_prefix}-ssh-private-key")

  # ---------------------------------------------------------------------------
  # Bootstrap payloads - the software-facing contract, unchanged across clouds
  # ---------------------------------------------------------------------------
  # This JSON is what the pre-baked image's first-boot script consumes. It is
  # byte-identical to the AWS module's, deliberately: the port changes where the
  # instance runs, not what Kafka is told. Delivery differs only in the envelope
  # (metadata.user_data, base64, read from http://169.254.169.254/opc/v2/ rather
  # than AWS's IMDS path).
  default_broker_extra_config = <<-EOT
    compression.type=lz4
    auto.leader.rebalance.enable=false
    num.network.threads=16
    num.replica.fetchers=4
    default.replication.factor=3
    log.cleaner.enable=false
    log.flush.interval.ms=300000
    log.index.interval.bytes=1000000
    log.flush.scheduler.interval.ms=300000
    log.retention.ms=14400000
  EOT

  broker_user_data = coalesce(var.broker_user_data_override, jsonencode({
    type      = "broker"
    extraConf = coalesce(var.broker_extra_config, local.default_broker_extra_config)
  }))

  controller_user_data = coalesce(var.controller_user_data_override, jsonencode({
    type = "controller"
  }))

  broker_metadata = merge(
    { user_data = base64encode(local.broker_user_data) },
    local.public_key != null ? { ssh_authorized_keys = local.public_key } : {}
  )

  controller_metadata = merge(
    { user_data = base64encode(local.controller_user_data) },
    local.public_key != null ? { ssh_authorized_keys = local.public_key } : {}
  )

  # ---------------------------------------------------------------------------
  # Reserved private IPs - the cluster's stable identity
  # ---------------------------------------------------------------------------
  broker_ip_addresses = [
    for i in range(var.broker_count) :
    try(var.broker_reserved_ip_addresses[i], null)
  ]

  controller_ip_addresses = [
    for i in range(var.controller_count) :
    try(var.controller_reserved_ip_addresses[i], null)
  ]

  broker_reserved_ips     = oci_core_private_ip.broker[*].ip_address
  controller_reserved_ips = oci_core_private_ip.controller[*].ip_address

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  create_identity = var.create_identity && var.tenancy_ocid != null

  matching_rule = coalesce(
    var.identity_matching_rule,
    "ALL {instance.compartment.id = '${var.compartment_id}'}"
  )

  # Narrow by default. See var.policy_statements for why the AWS role's
  # ec2:* / autoscaling:* / sts:AssumeRole set is not reproduced.
  default_policy_statements = [
    "Allow dynamic-group ${local.name_prefix}-nodes to inspect instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to read instance-family in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${local.name_prefix}-nodes to use log-content in compartment id ${var.compartment_id}",
  ]

  policy_statements = length(var.policy_statements) > 0 ? var.policy_statements : local.default_policy_statements

  # ---------------------------------------------------------------------------
  # Agent configuration
  # ---------------------------------------------------------------------------
  agent_plugins = [
    {
      name          = "Compute Instance Monitoring"
      desired_state = var.enable_monitoring_plugin ? "ENABLED" : "DISABLED"
    },
  ]
}
