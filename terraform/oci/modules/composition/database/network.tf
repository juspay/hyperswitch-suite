# =============================================================================
# Module-owned network access-control object (check sheet feature 16, FULL)
# =============================================================================
# An NSG, not a VCN security list. NSGs are membership-based and referenceable
# as a rule source, which makes them the closer analogue of the AWS module's
# aws_security_group; a security list is attached to a subnet and would put this
# database's access control in the vpc-network module's hands instead of this
# one's.
#
# Created EMPTY on purpose. The AWS module owns the security group object and
# catalog/units/security-rules - the last stack phase - writes the rules into
# it, reading security_group_id from this module's output. Keeping the object
# here and the rules there is what breaks the dependency cycle between the
# database and everything that talks to it. Do not add rules to this file to
# "simplify"; that reintroduces the cycle the split exists to break.
#
# The nsg_id output is the security_group_id output's replacement, and the
# contract the OCI security-rules port consumes.

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
