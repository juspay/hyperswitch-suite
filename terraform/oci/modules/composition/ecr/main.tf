# ============================================================================
# OCIR (OCI Registry) container repositories - equivalent of the AWS `ecr`
# composition module (aws_ecr_repository). No verified registry module
# exists for OCI Artifacts - raw oci provider resource.
# ============================================================================
resource "oci_artifacts_container_repository" "repositories" {
  for_each = var.repositories

  compartment_id = var.compartment_id
  display_name   = each.value.name
  is_immutable   = each.value.is_immutable
  is_public      = each.value.is_public

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
