# Placement lookups
# availability_domain resolves to the first AD when the caller leaves it null;
# ap-mumbai-1 has exactly one, so "first" is "the only one" there.

data "oci_identity_availability_domains" "this" {
  count = var.availability_domain == null ? 1 : 0

  compartment_id = var.compartment_id
}

data "oci_identity_fault_domains" "this" {
  count = length(var.fault_domains) == 0 ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
}

# Primary VNIC discovery - the other half of the static-address mechanism
# oci_core_private_ip needs a VNIC OCID; oci_core_instance does not export one,
# so it is only reachable through this data source.

data "oci_core_vnic_attachments" "broker" {
  count = var.broker_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.broker[count.index].id
}

data "oci_core_vnic_attachments" "controller" {
  count = var.controller_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.controller[count.index].id
}
