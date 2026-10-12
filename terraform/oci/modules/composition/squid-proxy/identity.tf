# Instance-principal identity - lets this fleet read its own config bucket
# from Object Storage at boot, with no other credential on a private-subnet,
# internetless instance.
#
# Only DEFINED tags are matchable in a dynamic-group rule (not freeform tags);
# the policy grants `read objects` only (config fetch is a GetObject). The
# dynamic group is forced to the tenancy-root compartment by the API itself,
# hence var.tenancy_ocid.

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

  # OCI stamps `Oracle-Tags` defined tags on identity resources at creation;
  # with var.defined_tags empty every plan tries to REMOVE them and the update
  # fails on the tenancy-root `oracle-tags` namespace this operator cannot write.
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

  # Same Oracle-Tags reasoning as the dynamic-group block above.
  lifecycle {
    ignore_changes = [defined_tags]
  }
}

locals {
  # ONLY the instance itself needs this tag; the instance_configuration and
  # instance_pool resources are not principals a dynamic group can match.
  identity_defined_tags = {
    "${oci_identity_tag_namespace.this.name}.${oci_identity_tag.component.name}" = local.display_name
  }
}
