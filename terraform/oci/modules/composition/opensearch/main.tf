locals {
  display_name = coalesce(var.display_name, "${var.environment}-${var.project_name}-opensearch")
}

# ============================================================================
# OCI Search with OpenSearch cluster - equivalent of the AWS `opensearch`
# composition module (which wraps terraform-aws-modules/opensearch/aws).
# No verified registry module exists for OCI Search with OpenSearch - raw
# oci provider resource.
# ============================================================================
resource "oci_opensearch_opensearch_cluster" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  software_version = var.software_version

  vcn_id                = var.vcn_id
  vcn_compartment_id    = var.compartment_id
  subnet_id             = var.subnet_id
  subnet_compartment_id = var.compartment_id
  nsg_id                = var.nsg_id

  data_node_count           = var.data_node_count
  data_node_host_ocpu_count = var.data_node_host_ocpu_count
  data_node_host_memory_gb  = var.data_node_host_memory_gb
  data_node_host_type       = var.data_node_host_type
  data_node_storage_gb      = var.data_node_storage_gb

  master_node_count           = var.master_node_count
  master_node_host_ocpu_count = var.master_node_host_ocpu_count
  master_node_host_memory_gb  = var.master_node_host_memory_gb
  master_node_host_type       = var.master_node_host_type

  opendashboard_node_count           = var.opendashboard_node_count
  opendashboard_node_host_ocpu_count = var.opendashboard_node_host_ocpu_count
  opendashboard_node_host_memory_gb  = var.opendashboard_node_host_memory_gb

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
