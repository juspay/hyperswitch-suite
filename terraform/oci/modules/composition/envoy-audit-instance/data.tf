# ap-mumbai-1 has exactly one availability domain. This stays a data source
# rather than a root.hcl local because AD names carry a tenancy-specific opaque
# prefix and are therefore not portable constants.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}