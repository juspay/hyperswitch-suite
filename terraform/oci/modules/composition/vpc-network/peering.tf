# Peering. AWS covers same-region, cross-region and cross-account peering with
# ONE resource plus an accepter; OCI splits that into three mechanisms, so the
# single AWS input pair cannot survive as one input:
#
#   same-region   -> Local Peering Gateway, one per side, limit 10 per VCN
#   cross-region  -> DRG + Remote Peering Connection
#   cross-tenancy -> either of the above, PLUS IAM policy statements in both
#                    tenancies (outside this module's scope)
#
# The requester/accepter split disappears: an LPG is symmetric, and whichever
# side sets peer_id establishes the connection.

locals {
  effective_drg_id = coalesce(
    var.drg_id,
    try(oci_core_drg.this[0].id, null),
    # Placeholder that is never routed to: local.rpc_peering_routes is empty
    # unless remote_peering_connections is non-empty, and the precondition
    # below rejects that combination without a DRG.
    "no-drg"
  )
}

resource "oci_core_drg" "this" {
  count = var.create_drg && var.drg_id == null ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-drg"

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_drg_attachment" "this" {
  count = (var.create_drg || var.drg_id != null) ? 1 : 0

  drg_id       = local.effective_drg_id
  display_name = "${local.name_prefix}-drg-attachment"

  network_details {
    id   = oci_core_vcn.this.id
    type = "VCN"
  }
}

resource "oci_core_local_peering_gateway" "this" {
  for_each = var.local_peering_gateways

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-lpg-${each.key}"

  # Set on exactly one side of the pair. The other side leaves it null and is
  # connected by its peer - there is no separate accepter resource.
  peer_id = each.value.peer_id

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_remote_peering_connection" "this" {
  for_each = var.remote_peering_connections

  compartment_id = var.compartment_id
  drg_id         = local.effective_drg_id
  display_name   = "${local.name_prefix}-rpc-${each.key}"

  peer_id          = each.value.peer_id
  peer_region_name = each.value.peer_region_name

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.create_drg || var.drg_id != null
      error_message = "remote_peering_connections requires a DRG: set create_drg = true or supply drg_id. Unlike AWS, cross-region peering on OCI is not a property of the VCN - it terminates on a Dynamic Routing Gateway."
    }
  }
}
