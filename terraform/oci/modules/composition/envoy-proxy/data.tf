# Lookups.

# AD names are tenancy-scoped and carry an opaque per-tenancy prefix, so the
# availability domain stays a data source rather than a hardcoded name.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# Tenancy-wide, region-scoped singleton. Object Storage addresses buckets by
# namespace + name, so every bucket and object resource needs this value.
data "oci_objectstorage_namespace" "this" {}
