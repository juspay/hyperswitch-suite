# =============================================================================
# Lookups
# =============================================================================

# ap-mumbai-1 has exactly one availability domain. This stays a data source
# rather than a root.hcl local because AD names carry a tenancy-specific opaque
# prefix ("AbCd:AP-MUMBAI-1-AD-1") and are therefore not portable constants.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# Tenancy-wide, region-scoped singleton. Object Storage addresses buckets by
# namespace + name, so the session-recording bucket needs this value.
data "oci_objectstorage_namespace" "this" {}
