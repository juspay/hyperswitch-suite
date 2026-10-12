# Module-owned, deliberately EMPTY network security group. NSGs are
# membership-based and referenceable as a rule source, so this is the closer
# analogue of the AWS security group. The module owns the empty object and
# exports its OCID; the security-last stack phase writes the rules.
resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
