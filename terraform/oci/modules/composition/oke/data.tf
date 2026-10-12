# =============================================================================
# oke - placement lookups
# =============================================================================
# Fault-domain NAMES are looked up, never written down. This is the same
# decision kafka/data.tf, cassandra/data.tf and clickhouse/data.tf already took
# for this port (the kafka check sheet's open question 9.3): "FAULT-DOMAIN-1/2/3
# is realm-invariant today but a literal in three modules is three places to
# drift, and the data source costs one API call."
#
# This module was the one that did NOT take it, and it cost a failed apply:
# `node_pools[*].fault_domains` defaulted to the short form `["FD-1","FD-2",
# "FD-3"]`, which the OKE API rejects outright -
#   400-InvalidParameter, Invalid nodeConfigDetails.placementConfigs[].faultDomains
# The short form is not an OCI concept at all; it is the wrapped registry
# module's own internal placeholder (`modules/workers/locals.tf`:
# `fault_domains_all = formatlist("FD-%v", [1, 2, 3])`), used only as a default
# for VIRTUAL node pools, and it is never translated to a real name on the
# managed-node-pool path. See build-log entry C16.
#
# DIVERGENCE from the kafka/cassandra/clickhouse idiom, which resolves fault
# domains for ONE availability domain: those modules pin each instance to a
# single AD, so a single-AD lookup is exact. A managed OKE node pool emits the
# SAME `fault_domains` list into every `placement_configs` block - one per AD in
# the pool's placement - so the only list that is valid for all of them is the
# INTERSECTION across the region's ADs (see local.region_fault_domains). In
# ap-mumbai-1 there is exactly one AD and the intersection is that AD's set;
# in a three-AD region the intersection is what keeps the pool plannable.

data "oci_identity_availability_domains" "this" {
  # An AD listing is a tenancy-level call. tenancy_id when the caller supplies
  # it, compartment_id otherwise - the fallback is verified working in
  # ap-mumbai-1 and is what the consuming unit relies on.
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
