# =============================================================================
# Placement lookups (C13)
# =============================================================================
# ap-mumbai-1 has exactly one availability domain, so this list has one entry
# and index 0 is not a lottery. It stays a data source rather than a hardcoded
# name because AD names are tenancy-scoped and carry an opaque prefix
# ("Niou:AP-MUMBAI-1-AD-1" in this tenancy) that differs between tenancies -
# the one fact that makes an availability domain unsafe to write into a
# root.hcl local or into a unit's inputs. Identical reasoning, and identical
# wording, to squid-proxy/data.tf, envoy-proxy/data.tf, cassandra/data.tf,
# kafka/data.tf, bastion-host/data.tf and file-storage/main.tf - this module
# was the last OCI composition module still without the lookup, because it was
# the only one that believed it would never need an AD.
#
# Unconditional rather than count-gated on `var.availability_domain == null`
# (the cassandra/kafka shape), because the COUNT of the returned list is what
# arms the is_regionally_durable precondition in outputs.tf. That guard is the
# point of this data source: without it, "is_regionally_durable = true in a
# single-AD region" is only discoverable by a real create call against the real
# API, which is how C13 was found.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}
