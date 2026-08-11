locals {
  name_prefix = "${var.environment}-${var.project_name}-kafka"
}

# ============================================================================
# Network Security Groups
# ============================================================================
resource "oci_core_network_security_group" "broker" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-broker-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group" "controller" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-controller-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "broker_self_ingress" {
  network_security_group_id = oci_core_network_security_group.broker.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.broker.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "broker_self_egress" {
  network_security_group_id = oci_core_network_security_group.broker.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.broker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "broker_from_controller" {
  network_security_group_id = oci_core_network_security_group.broker.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.controller.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "broker_to_controller" {
  network_security_group_id = oci_core_network_security_group.broker.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.controller.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "controller_self_ingress" {
  network_security_group_id = oci_core_network_security_group.controller.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.controller.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "controller_self_egress" {
  network_security_group_id = oci_core_network_security_group.controller.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.controller.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "controller_from_broker" {
  network_security_group_id = oci_core_network_security_group.controller.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.broker.id
  source_type               = "NETWORK_SECURITY_GROUP"
}

resource "oci_core_network_security_group_security_rule" "controller_to_broker" {
  network_security_group_id = oci_core_network_security_group.controller.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.broker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
}

# ============================================================================
# IAM - Dynamic Group + Policy
# ============================================================================
resource "oci_identity_dynamic_group" "kafka" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for Kafka cluster nodes"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.kafka-cluster.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "kafka" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Least-privilege policy for Kafka cluster nodes"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.kafka.name} to read instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.kafka.name} to use log-content in compartment id ${var.compartment_id}",
  ]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Controller node (single, KRaft controller - equivalent of AWS aws_instance.controller)
# ============================================================================
module "controller_node" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = 1
  instance_display_name = "${local.name_prefix}-controller"

  shape                       = var.controller_shape
  instance_flex_ocpus         = var.controller_ocpus
  instance_flex_memory_in_gbs = var.controller_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs    = var.controller_boot_volume_size_in_gbs
  block_storage_sizes_in_gbs = [var.controller_metadata_volume_size_in_gbs]

  subnet_ocids         = [var.controller_subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.controller.id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.controller_user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.kafka-cluster" = "true" })
  defined_tags  = var.defined_tags
}

# ============================================================================
# Broker nodes (equivalent of AWS aws_instance.broker, count = broker_count)
# ============================================================================
module "broker_nodes" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = var.broker_count
  instance_display_name = "${local.name_prefix}-broker"

  shape                       = var.broker_shape
  instance_flex_ocpus         = var.broker_ocpus
  instance_flex_memory_in_gbs = var.broker_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs    = var.broker_boot_volume_size_in_gbs
  block_storage_sizes_in_gbs = [var.broker_data_volume_size_in_gbs]

  subnet_ocids         = [var.broker_subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.broker.id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.broker_user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.kafka-cluster" = "true" })
  defined_tags  = var.defined_tags

  depends_on = [module.controller_node]
}
