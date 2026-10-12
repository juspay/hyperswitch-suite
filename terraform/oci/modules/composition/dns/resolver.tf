# Private view, and its attachment to the VCN's resolver
#
# AWS expresses a private zone and its VPC visibility in ONE resource; OCI needs
# three objects with different owners:
#     oci_dns_view     (PRIVATE)   this module  - groups private zones
#     oci_dns_zone     (view_id)   this module  - the zone itself
#     oci_dns_resolver             OCI, not us  - makes it resolvable
#
# The resolver is auto-created per VCN, so the Terraform resource can only
# UPDATE it (never create one). THE FAILURE MODE IS SILENT: skip the attachment
# and the view, zone and records still apply cleanly, resolving from nowhere.

# -----------------------------------------------------------------------------
# The private view
# -----------------------------------------------------------------------------
# ONE view per module instantiation, shared by every private zone it creates,
# not one view per zone - keeps the resolver's attached_views list small.
resource "oci_dns_view" "private" {
  count = (local.has_private_zones && var.private_view_id == null) ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-private"
  scope          = "PRIVATE"

  freeform_tags = merge(local.common_freeform_tags, { "component" = "dns" })
}

# -----------------------------------------------------------------------------
# The VCN's own resolver
# -----------------------------------------------------------------------------
# Resolved via data source so no new resolver-id output is needed from the
# VCN module - the association maps vcn_id -> the auto-created resolver's OCID.
data "oci_core_vcn_dns_resolver_association" "this" {
  count = local.attach_resolver ? 1 : 0

  vcn_id = var.vcn_id

  lifecycle {
    precondition {
      condition     = var.vcn_id != null
      error_message = "vcn_id is required when any zone has type = \"private\" and attach_private_views_to_vcn_resolver is true. Without it the private zones apply successfully and resolve from nowhere inside the VCN - a silent failure, which is why this is a hard error instead."
    }
  }
}

# This shows as "will be created" in plan - a new state entry, not a real
# provision: the provider's Create issues UpdateResolver. destroy detaches the
# views and forgets it. Judge by resolver_id being a real OCID, not the verb.
resource "oci_dns_resolver" "this" {
  count = local.attach_resolver ? 1 : 0

  resolver_id    = data.oci_core_vcn_dns_resolver_association.this[0].dns_resolver_id
  compartment_id = var.compartment_id
  display_name   = var.resolver_display_name
  scope          = "PRIVATE"

  # AUTHORITATIVE LIST: anything attached out of band is detached on the next
  # apply. additional_attached_view_ids lets a second owner coexist.
  dynamic "attached_views" {
    for_each = toset(concat(
      local.private_view_id != null ? [local.private_view_id] : [],
      var.additional_attached_view_ids,
    ))

    content {
      view_id = attached_views.value
    }
  }

  freeform_tags = merge(local.common_freeform_tags, { "component" = "dns" })

  lifecycle {
    precondition {
      condition     = var.vcn_id != null
      error_message = "vcn_id is required when any zone has type = \"private\" and attach_private_views_to_vcn_resolver is true. Without it the private zones apply successfully and resolve from nowhere inside the VCN - a silent failure, which is why this is a hard error instead."
    }
  }
}
