locals {
  name_prefix = "${var.environment}-${var.project_name}-cassandra"
}

# ============================================================================
# Network Security Group (equivalent of AWS aws_security_group.cassandra +
# aws_security_group_rule self/vpc-endpoint rules)
# ============================================================================
resource "oci_core_network_security_group" "cassandra" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "self_ingress" {
  network_security_group_id = oci_core_network_security_group.cassandra.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  source                    = oci_core_network_security_group.cassandra.id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Allow all TCP traffic from itself"
}

resource "oci_core_network_security_group_security_rule" "self_egress" {
  network_security_group_id = oci_core_network_security_group.cassandra.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.cassandra.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Allow all TCP traffic to itself"
}

resource "oci_core_network_security_group_security_rule" "endpoint_egress" {
  count = var.vcn_endpoint_nsg_id != null ? 1 : 0

  network_security_group_id = oci_core_network_security_group.cassandra.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = var.vcn_endpoint_nsg_id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "HTTPS access to VCN service endpoints"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

# ============================================================================
# IAM - Dynamic Group + Policy (equivalent of AWS aws_iam_role +
# aws_iam_instance_profile; OCI compute instances authenticate as members of
# a dynamic group via Instance Principals, no attached "profile" resource)
# ============================================================================
resource "oci_identity_dynamic_group" "cassandra" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for Cassandra cluster nodes"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.cassandra-cluster.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "cassandra" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Least-privilege policy for Cassandra cluster nodes"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.cassandra.name} to read instances in compartment id ${var.compartment_id}",
    "Allow dynamic-group ${oci_identity_dynamic_group.cassandra.name} to use log-content in compartment id ${var.compartment_id}",
  ]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Logging (equivalent of AWS aws_cloudwatch_log_group)
# ============================================================================
resource "oci_logging_log_group" "cassandra" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-logs"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Compute Instances (using the official, verified
# oracle-terraform-modules/compute-instance/oci registry module - equivalent
# of the AWS aws_instance + aws_network_interface + aws_ebs_volume resources)
# ============================================================================
module "cassandra_nodes" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = var.node_count
  instance_display_name = "${local.name_prefix}-node"

  shape                       = var.shape
  instance_flex_ocpus         = var.instance_flex_ocpus
  instance_flex_memory_in_gbs = var.instance_flex_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  # Second attached block volume for the Cassandra data directory, one per node
  block_storage_sizes_in_gbs = [var.data_volume_size_in_gbs]

  subnet_ocids         = [var.subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.cassandra.id]
  assign_public_ip     = false

  ssh_authorized_keys = var.ssh_authorized_keys
  user_data           = var.user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.cassandra-cluster" = "true" })
  defined_tags  = var.defined_tags
}
