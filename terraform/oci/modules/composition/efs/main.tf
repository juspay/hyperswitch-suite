# ============================================================================
# OCI File Storage Service - equivalent of the AWS `efs` composition module
# (which wraps terraform-aws-modules/efs/aws). No verified registry module
# exists for OCI FSS - raw oci provider resources.
# ============================================================================
resource "oci_file_storage_file_system" "this" {
  for_each = var.file_systems

  compartment_id      = var.compartment_id
  availability_domain = each.value.availability_domain
  display_name        = each.value.display_name
  kms_key_id          = each.value.kms_key_id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_file_storage_mount_target" "this" {
  for_each = var.file_systems

  compartment_id      = var.compartment_id
  availability_domain = each.value.availability_domain
  display_name        = "${each.value.display_name}-mt"
  subnet_id           = each.value.mount_target_subnet_id
  nsg_ids             = each.value.mount_target_nsg_ids

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_file_storage_export" "this" {
  for_each = var.file_systems

  export_set_id  = oci_file_storage_mount_target.this[each.key].export_set_id
  file_system_id = oci_file_storage_file_system.this[each.key].id
  path           = each.value.export_path
}
