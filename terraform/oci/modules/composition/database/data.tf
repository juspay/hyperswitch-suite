# Availability-domain listing. ap-mumbai-1 has exactly one AD, so index 0 is
# not a lottery; it stays a data source because AD names carry a tenancy-scoped
# opaque prefix that differs between tenancies, making them unsafe to hardcode.
# Unconditional, because the count of the returned list arms the
# is_regionally_durable precondition in outputs.tf.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}
