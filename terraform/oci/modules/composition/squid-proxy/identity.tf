# =============================================================================
# Instance-principal identity - lets this fleet read its own config bucket
# from Object Storage at boot, with no other credential available on a
# private-subnet instance with no internet route for an API key.
# =============================================================================
# Folded in here (2026-09-10, user-requested), replacing a shared
# `proxy-identity` composition module used by both squid-proxy and
# envoy-proxy. The shared module bought nothing but an extra catalog unit and
# a cross-unit dependency edge for two fleets whose identity has zero
# interaction with each other beyond needing the same OCI mechanism. The one
# real cost of folding it in per-module is one extra tag namespace (this
# module's own, not shared with envoy-proxy's) - accepted, since tag
# namespace names are cheap and self-containment is worth more here than the
# small resource-count saving.
#
# DESIGN, unchanged from the original proxy-identity module:
#   - Freeform tags are NOT matchable in a dynamic-group rule (only DEFINED
#     tags are - confirmed, oracle-consulted) - hence the tag namespace + tag
#     pair below, rather than reusing local.freeform_tags.
#   - `read objects`, not `manage objects` - config fetch is a GetObject, no
#     write needed.
#   - No `inspect buckets` on the policy - the bucket-scoped `where` clause
#     does not restrict ListBuckets, so adding it would leak the bucket list
#     beyond what a boot-time single-object fetch needs.
#   - The tag namespace is COMPARTMENT-scoped (live-verified 2026-09-09), so
#     it is covered by the same `manage all-resources in compartment <env>`
#     grant everything else in this compartment uses. Only the dynamic group
#     is genuinely forced to the tenancy root by the API itself
#     (400-InvalidParameter: "Dynamic group can only be created in the
#     tenancy compartment") - hence var.tenancy_ocid below, the one new input
#     this module did not need before.
# =============================================================================

resource "oci_identity_tag_namespace" "this" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-identity"
  description    = "Defined-tag namespace for the ${local.display_name} fleet's instance-principal identity matching."

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_tag" "component" {
  tag_namespace_id = oci_identity_tag_namespace.this.id
  name             = "component"
  description      = "Marks an instance as a member of the ${local.display_name} fleet, for dynamic-group matching."
}

resource "oci_identity_dynamic_group" "this" {
  compartment_id = var.tenancy_ocid
  name           = "${local.name_prefix}-fleet"
  description    = "Squid-proxy fleet instances (${local.display_name}), matched by defined tag - freeform tags are not matchable. Grants instance-principal access to fetch this fleet's config/allowlist at boot."

  matching_rule = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${oci_identity_tag_namespace.this.name}.${oci_identity_tag.component.name}.value = '${local.display_name}'}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # OCI stamps its own `Oracle-Tags` defined tags (CreatedBy/CreatedOn) onto
  # identity resources at creation. With var.defined_tags empty, every
  # subsequent plan then tries to REMOVE them, and UpdateDynamicGroup fails
  # with "The following tag namespaces / keys are not authorized or not
  # found: 'oracle-tags'" - `Oracle-Tags` is a tenancy-root namespace this
  # compartment-scoped operator cannot write. Confirmed live 2026-09-10: the
  # create succeeds, only the no-op update fails. Ignoring the attribute
  # keeps re-applies clean without needing a tenancy-level grant.
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_identity_policy" "this" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-identity"
  description    = "Instance-principal read access for the ${local.display_name} fleet to its own config bucket. GetObject only - no bucket listing, no write."

  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.this.name} to read objects in compartment id ${var.compartment_id} where all { target.bucket.name = '${local.config_bucket_name}' }",
  ]

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # See squid-proxy/identity.tf for the full reasoning: OCI stamps its own
  # `Oracle-Tags` defined tags on identity resources at creation, and stripping
  # them back to an empty map needs a tenancy-root grant this operator lacks.
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

locals {
  # Merged into launch_details.defined_tags in compute.tf - ONLY the instance
  # itself needs this tag; the instance_configuration and instance_pool
  # resources are not principals a dynamic group can match against.
  identity_defined_tags = {
    "${oci_identity_tag_namespace.this.name}.${oci_identity_tag.component.name}" = local.display_name
  }
}
