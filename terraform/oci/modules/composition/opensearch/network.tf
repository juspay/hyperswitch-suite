# =============================================================================
# Module-owned, deliberately EMPTY NSG (check sheet feature 10, FULL)
# =============================================================================
# Same convention as the sibling data-tier modules (database, oci-cache-valkey,
# kafka, cassandra, clickhouse): this module owns the NSG object, and
# composition/security-rules - the security-last stack phase - writes the rules
# into it by reading nsg_id from this module's outputs. Do not add rules here.
#
# THE POSTURE THIS REPLACES IS WORTH STATING PLAINLY, so nobody reads
# "NSG-gated only" as a downgrade. The AWS module pairs its VPC-attached domain
# with access_policy_statements whose principal identifiers are ["*"] - i.e. the
# effective policy is already "anyone who can reach it on the network", with the
# security group doing all the real work. An NSG-gated OCI cluster is therefore
# like-for-like, not weaker. It is also not strong: if a narrower resource policy
# is ever wanted, OCI's answer is fine-grained access control (var.security_mode
# plus a master user), not a resource policy - a different mechanism, not a
# missing one.
#
# The cluster resource takes exactly ONE nsg_id, which is why AWS's four
# security-group variables collapse into create_nsg + nsg_id.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
