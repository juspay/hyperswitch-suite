# =============================================================================
# Placement lookups
# =============================================================================
# The check sheet (open question 9.3) asks whether fault-domain names should be
# a root.hcl constant duplicated per module or looked up. They are looked up
# here: FAULT-DOMAIN-1/2/3 is realm-invariant today but a literal in three
# modules is three places to drift, and the data source costs one API call.
#
# availability_domain resolves to the first AD when the caller leaves it null.
# ap-mumbai-1 has exactly one, so "first" is "the only one" there; in a 3-AD
# region the caller should pass the AD explicitly rather than accept the first.

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
# oci_core_private_ip needs a VNIC OCID, and oci_core_instance does not export
# one: the instance exposes its own OCID and its primary private IP string, but
# the VNIC object between them is only reachable through this data source.
# See network.tf for why the reserved private IP hangs off the primary VNIC.

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
