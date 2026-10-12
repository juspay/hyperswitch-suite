# =============================================================================
# Placement lookups
# =============================================================================
# Looked up rather than passed in as a root.hcl constant, for the reason the
# kafka check sheet's open question 9.3 raises: FAULT-DOMAIN-1/2/3 is
# realm-invariant today, but the same literal in three modules is three places
# to drift.

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
# Primary VNIC discovery
# =============================================================================
# oci_core_private_ip needs a VNIC OCID and oci_core_instance does not export
# one. See network.tf for why the ring's stable identity hangs off a reserved
# private IP rather than off the instance.

data "oci_core_vnic_attachments" "node" {
  count = var.node_count

  compartment_id = var.compartment_id
  instance_id    = oci_core_instance.cassandra[count.index].id
}
