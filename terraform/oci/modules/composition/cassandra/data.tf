# Placement lookups.
data "oci_identity_availability_domains" "this" {
  count = var.availability_domain == null ? 1 : 0

  compartment_id = var.compartment_id
}

data "oci_identity_fault_domains" "this" {
  count = length(var.fault_domains) == 0 ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
}

# Primary VNIC discovery - oci_core_private_ip needs a VNIC OCID, which the
# instance resource does not export.
data "oci_core_vnic_attachments" "node" {
  count = var.node_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.cassandra[count.index].id
}
