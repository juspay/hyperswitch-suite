# AD names carry a tenancy-specific opaque prefix, so they are resolved, not hardcoded.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# Object Storage addresses buckets by namespace + name.
data "oci_objectstorage_namespace" "this" {}
