# =============================================================================
# Lookups
# =============================================================================

# ap-mumbai-1 has exactly one availability domain, so this list has one entry
# and index 0 is not a lottery. It stays a data source rather than a hardcoded
# name because AD names are tenancy-scoped and carry an opaque prefix
# ("AbCd:AP-MUMBAI-1-AD-1") that differs between tenancies - the one fact that
# makes an availability domain unsafe to write into a root.hcl local.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# Tenancy-wide, region-scoped singleton. Object Storage addresses buckets by
# namespace + name rather than by a globally unique name the way S3 does, so
# every bucket and object resource needs this value.
data "oci_objectstorage_namespace" "this" {}
