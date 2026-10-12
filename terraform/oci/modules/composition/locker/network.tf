# Module-owned network access-control object. An NSG, not a VCN security list:
# only an NSG can be named as a rule's source (83% of the live AWS rule set is
# peer-group references), only NSG rules are standalone resources a LATER stack
# phase can write into, and a security list would be an allow no NSG could
# narrow - the wrong property for the one subnet holding cardholder data.
# CREATED EMPTY on purpose, so the security-last stack phase writes the rules.
# The two other AWS security groups (instances, ALB) have no counterpart here
# because there is no VM fleet or ALB - an NSG with no members is silently inert.

resource "oci_core_network_security_group" "locker_database" {
  count = var.create_nsg && var.create_database ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-db-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
