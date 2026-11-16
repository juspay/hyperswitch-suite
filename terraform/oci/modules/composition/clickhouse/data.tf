# =============================================================================
# Placement lookups
# =============================================================================

data "oci_identity_availability_domains" "this" {
  count = var.availability_domain == null ? 1 : 0

  compartment_id = var.compartment_id
}

data "oci_identity_fault_domains" "this" {
  count = length(var.fault_domains) == 0 ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
}

# =============================================================================
# Primary VNIC discovery - the other half of the static-address mechanism
# =============================================================================

data "oci_core_vnic_attachments" "keeper" {
  count = var.keeper_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.keeper[count.index].id
}

data "oci_core_vnic_attachments" "server" {
  count = var.server_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.server[count.index].id
}
