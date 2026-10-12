# oke - availability-domain and fault-domain placement lookups.

data "oci_identity_availability_domains" "this" {
  # tenancy_id when supplied, compartment_id otherwise - a tenancy-level call.
  compartment_id = coalesce(var.tenancy_id, var.compartment_id)
}

data "oci_identity_fault_domains" "this" {
  for_each = {
    for ad in data.oci_identity_availability_domains.this.availability_domains :
    ad.name => ad.name
  }

  compartment_id      = var.compartment_id
  availability_domain = each.value
}
