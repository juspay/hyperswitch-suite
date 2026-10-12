# =============================================================================
# Module-owned network access-control object (check sheet features 3-5)
# =============================================================================
# An NSG, not a VCN security list. This is not a per-module judgement call - it
# is the binding recommendation of
# docs/multi-cloud-parity/oci/network-security-model.md section 5, Option A
# ("NSGs only"), and the reasons apply with extra force here:
#
#   * Only an NSG can be named as a rule's source
#     (source_type = "NETWORK_SECURITY_GROUP"). 83% of the live AWS rule set is
#     peer-group references, including every rule that reaches this database.
#   * Only NSG rules are standalone resources, so a LATER stack phase can write
#     into an NSG this state owns. Security-list rules are inline-only, which
#     would force the locker's ingress rules back into whoever owns the subnet.
#   * Security lists and NSGs evaluate as a UNION (OR). A security list on the
#     locker-database tier would be an allow that no NSG could narrow - the
#     wrong property for the one subnet holding cardholder data.
#
# CREATED EMPTY, ON PURPOSE. Exactly the pattern in
# composition/database/network.tf: this module owns the object and exports its
# OCID; composition/security-rules - the last stack phase - writes the rules.
# Keeping the object here and the rules there is what breaks the dependency
# cycle between the locker's database and everything that talks to it. Do not
# add rules to this file to "simplify"; that reintroduces the cycle the split
# exists to break.
#
# The `nsg_id` output replaces the AWS module's `db_security_group_id`.
#
# WHAT IS NOT HERE, and why (check sheet features 3 and 4, and section 4.1):
# the AWS module owns THREE security groups - the locker instances', the ALB's,
# and (via the nested database) the database's. Under this port's shape there
# is no locker VM fleet and no ALB (see the header of database.tf), so two of
# the three have no VNIC to attach to. An NSG with no members is silently
# inert: perfect rules, zero effect, and the symptom is a connectivity failure
# rather than an exposure. Creating them "for later" would be creating exactly
# that. The card-vault workload's own network identity is the OKE pod NSG
# (`pod_nsg_ids` on the node pool), owned by composition/oke.

resource "oci_core_network_security_group" "locker_database" {
  count = var.create_nsg && var.create_database ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-db-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
