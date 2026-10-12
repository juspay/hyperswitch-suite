# =============================================================================
# Instance-principal identity - lets this fleet read its own config bucket
# from Object Storage at boot, with no other credential available on a
# private-subnet instance with no internet route for an API key.
# =============================================================================
# Folded in here (2026-09-10, user-requested), replacing a shared
# `proxy-identity` composition module used by both squid-proxy and
# envoy-proxy. See squid-proxy/identity.tf for the full design rationale -
# this file is deliberately kept the same shape so the two do not drift.
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
  description    = "Envoy-proxy fleet instances (${local.display_name}), matched by defined tag - freeform tags are not matchable. Grants instance-principal access to fetch this fleet's envoy.yaml at boot."

  matching_rule = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${oci_identity_tag_namespace.this.name}.${oci_identity_tag.component.name}.value = '${local.display_name}'}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # See squid-proxy/identity.tf for the full reasoning: OCI stamps its own
  # `Oracle-Tags` defined tags on identity resources at creation, and stripping
  # them back to an empty map needs a tenancy-root grant this operator lacks.
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
