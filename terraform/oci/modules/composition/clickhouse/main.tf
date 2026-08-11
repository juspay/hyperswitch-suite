locals {
  name_prefix = "${var.environment}-${var.project_name}-clickhouse"
}

# ============================================================================
# Network Security Groups (equivalent of AWS keeper/server security groups
# + intra-cluster rules)
# ============================================================================
resource "oci_core_network_security_group" "keeper" {
  count = var.keeper_count > 0 ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-keeper-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group" "server" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-server-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "keeper_self_ingress" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.keeper[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.keeper[0].id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "keeper_self_egress" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.keeper[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.keeper[0].id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "keeper_from_server" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.keeper[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.server.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "keeper_to_server" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.keeper[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.server.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "server_self_ingress" {
  network_security_group_id = oci_core_network_security_group.server.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.server.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "server_self_egress" {
  network_security_group_id = oci_core_network_security_group.server.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.server.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "server_from_keeper" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.server.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.keeper[0].id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "server_to_keeper" {
  count                     = var.keeper_count > 0 ? 1 : 0
  network_security_group_id = oci_core_network_security_group.server.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.keeper[0].id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

# ============================================================================
# IAM - Dynamic Group + Policy
# ============================================================================
resource "oci_identity_dynamic_group" "clickhouse" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for Clickhouse cluster nodes"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.clickhouse-cluster.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "clickhouse" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Least-privilege policy for Clickhouse cluster nodes"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.clickhouse.name} to read instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.clickhouse.name} to use log-content in compartment id ${var.compartment_id}",
  ]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Keeper nodes (compute-instance module)
# ============================================================================
module "keeper_nodes" {
  count   = var.keeper_count > 0 ? 1 : 0
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = var.keeper_count
  instance_display_name = "${local.name_prefix}-keeper"

  shape                       = var.keeper_shape
  instance_flex_ocpus         = var.keeper_ocpus
  instance_flex_memory_in_gbs = var.keeper_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs    = var.keeper_boot_volume_size_in_gbs
  block_storage_sizes_in_gbs = [var.keeper_data_volume_size_in_gbs]

  subnet_ocids         = [var.keeper_subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.keeper[0].id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.keeper_user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.clickhouse-cluster" = "true" })
  defined_tags  = var.defined_tags
}

# ============================================================================
# Server nodes (compute-instance module)
# ============================================================================
module "server_nodes" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = var.server_count
  instance_display_name = "${local.name_prefix}-server"

  shape                       = var.server_shape
  instance_flex_ocpus         = var.server_ocpus
  instance_flex_memory_in_gbs = var.server_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs    = var.server_boot_volume_size_in_gbs
  block_storage_sizes_in_gbs = [var.server_data_volume_size_in_gbs]

  subnet_ocids         = [var.server_subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.server.id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.server_user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.clickhouse-cluster" = "true" })
  defined_tags  = var.defined_tags

  depends_on = [module.keeper_nodes]
}

# ============================================================================
# Internal Load Balancer (equivalent of AWS internal aws_lb + target groups)
# ============================================================================
resource "oci_load_balancer_load_balancer" "clickhouse" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-lb"
  shape          = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }
  subnet_ids                 = [var.lb_subnet_id]
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.server.id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_load_balancer_backend_set" "clickhouse" {
  name             = "${local.name_prefix}-bes"
  load_balancer_id = oci_load_balancer_load_balancer.clickhouse.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol          = "HTTP"
    port              = var.clickhouse_port
    url_path          = "/ping"
    return_code       = 200
    interval_ms       = 30000
    timeout_in_millis = 5000
    retries           = 2
  }
}

resource "oci_load_balancer_backend" "clickhouse" {
  count = var.server_count

  load_balancer_id = oci_load_balancer_load_balancer.clickhouse.id
  backendset_name  = oci_load_balancer_backend_set.clickhouse.name
  ip_address       = module.server_nodes.private_ip[count.index]
  port             = var.clickhouse_port
}

resource "oci_load_balancer_listener" "clickhouse" {
  name                     = "${local.name_prefix}-listener"
  load_balancer_id         = oci_load_balancer_load_balancer.clickhouse.id
  default_backend_set_name = oci_load_balancer_backend_set.clickhouse.name
  port                     = var.clickhouse_port
  protocol                 = "HTTP"
}
