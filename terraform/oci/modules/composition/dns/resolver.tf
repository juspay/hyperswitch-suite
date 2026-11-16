# =============================================================================
# Private view, and its attachment to the VCN's resolver
#
# THIS FILE HAS NO AWS COUNTERPART. It exists because of one structural
# difference (route53.md feature 2, PARTIAL) and is split out rather than
# folded into main.tf so that difference is impossible to miss.
#
# AWS, one resource:
#
#     resource "aws_route53_zone" "internal" {
#       name = "hyperswitch.internal"
#       vpc { vpc_id = var.vpc_id }        # zone AND visibility
#     }
#
# OCI, three objects with three different owners:
#
#     oci_dns_view      (PRIVATE)   this module        - groups private zones
#     oci_dns_zone      (view_id)   this module        - the zone itself
#     oci_dns_resolver              OCI, NOT us        - makes it resolvable
#
# The resolver is the part with no analogue at all: OCI auto-creates one
# resolver per VCN at VCN-creation time. The Terraform resource can only
# UPDATE an existing resolver, addressed by resolver_id - it never creates one.
# So this module must reach into an object the vpc-network module implicitly
# owns and modify it.
#
# THE FAILURE MODE IS SILENT. Skip the attachment and the view, the zone and
# every record still apply cleanly, and resolve from nowhere inside the VCN.
# There is no apply-time error, because the zone resource neither knows nor
# cares whether any resolver has been told to use it.
# =============================================================================

# -----------------------------------------------------------------------------
# The private view
# -----------------------------------------------------------------------------
# ONE view per module instantiation, shared by every private zone it creates -
# not one view per zone.
#
# Reason: the resolver's attached_views list is authoritative and capped, and
# every additional view is another entry this module has to keep attached and
# another thing a second unit could clobber. A view is a namespace grouping,
# not a security boundary - zones inside one view do not leak into each other -
# so per-zone views would buy churn and no isolation. route53.md open question
# 3 asks whether the platform wants this centralised instead; `private_view_id`
# is the seam for that answer, so adopting it later needs no module change.
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
# A data lookup, not a dependency output, and that is a deliberate narrowing of
# the coupling route53.md section 4 anticipated. The check sheet assumed this
# module would need a new resolver-id output from the VCN/foundation module.
# It does not: oci_core_vcn_dns_resolver_association resolves vcn_id -> the
# auto-created resolver's OCID directly, so vpc-network's published output
# contract needs no change and the unit passes the vcn_id it already has.
# (Skill section 2: do not buy coupling you do not need.)
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

# NOTE ON THE PLAN OUTPUT, correcting route53.md's rung-5 expectation:
# this WILL show as "will be created" in `terragrunt plan`. That is a Terraform
# statement about a new state entry, not about OCI - the provider's Create
# implementation for oci_dns_resolver issues an UpdateResolver call against the
# resolver_id it is given. No resolver is provisioned. Correspondingly,
# `terraform destroy` does NOT delete the resolver; it detaches the views and
# forgets it. Judge the plan by resolver_id being a real OCID rather than by
# the create/update verb.
resource "oci_dns_resolver" "this" {
  count = local.attach_resolver ? 1 : 0

  resolver_id    = data.oci_core_vcn_dns_resolver_association.this[0].dns_resolver_id
  compartment_id = var.compartment_id
  display_name   = var.resolver_display_name
  scope          = "PRIVATE"

  # AUTHORITATIVE LIST. Anything attached to this resolver by another unit, or
  # by hand in the console, and not named here gets detached on the next apply.
  # additional_attached_view_ids exists so a second owner can coexist.
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
