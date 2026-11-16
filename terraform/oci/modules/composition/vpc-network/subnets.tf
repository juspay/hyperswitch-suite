###############################################################################
# Subnets - one REGIONAL subnet per tier
#
# availability_domain is deliberately never set. Provider doc, verbatim:
# "Oracle recommends creating regional subnets because they're more flexible
# and make it easier to implement failover across availability domains ... To
# create a regional subnet, omit this attribute." Pinning a subnet to an AD
# means resources in it can only be created in that AD - strictly worse, with
# no upside in ap-mumbai-1, which has exactly ONE availability domain.
#
# Residual risk, not mitigable here and recorded in check sheet section 4.2: a
# single-AD region cannot offer AWS-equivalent in-region availability. Spread
# across the 3 fault domains is a compute-module concern (instances, node
# pools), never encoded in this module. The only real datacentre-failure story
# is cross-region to ap-hyderabad-1.
#
# There are no Kubernetes subnet tags here (check sheet feature 22 / section
# 4.7): OKE does not read kubernetes.io/role/elb or /internal-elb the way the
# AWS load balancer controller does, so enable_eks_elb_tag and
# enable_eks_internal_elb_tag are dropped. The OKE unit consumes
# subnets_by_tier instead and passes OCIDs to options.service_lb_subnet_ids
# explicitly.
###############################################################################

resource "oci_core_subnet" "this" {
  for_each = local.all_subnets

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  cidr_block     = each.value.cidr
  display_name   = "${local.name_prefix}-${each.key}"

  # Not updatable - changing a subnet DNS label replaces the subnet.
  dns_label = each.value.dns_label

  # Stronger than AWS's map_public_ip_on_launch = false, which only changes a
  # default: this forbids a public IP on any VNIC in the subnet outright.
  # Never combined with prohibit_internet_ingress - the provider states only
  # one or the other should be specified.
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic

  route_table_id = oci_core_route_table.this[each.value.route_table].id

  # security_list_ids is set EXPLICITLY on every subnet rather than left to
  # inherit (../network-security-model.md section 5.2). It points at the
  # emptied default security list, which also orders the graph so the list is
  # neutered before any subnet attaches to it. Belt and braces: the model is
  # NSG-only, and because security-list rules union (OR) with NSG rules, a
  # populated list here would silently widen every NSG in the subnet.
  #
  # Deliberately not `[]`: open question 2 on the check sheet records that the
  # provider does not document whether an explicit empty list means "no
  # security lists" or "inherit the VCN default", and this design must not
  # depend on the answer.
  #
  # Attach the dedicated bastion egress list to the management tier ONLY.
  # Every other tier keeps the emptied default. This is the single named
  # exception to the NSG-only model (security-lists.tf) - required because the
  # OCI Bastion service VNIC has no NSG support and must egress via the
  # management subnet's security list. The default list stays empty and the
  # other 12 subnets are untouched.
  security_list_ids = (
    each.key == "management" && can(local.named_subnets.management.cidr)
    ? [oci_core_security_list.management_bastion[0].id]
    : [oci_core_default_security_list.this.id]
  )

  dhcp_options_id = var.create_dhcp_options ? oci_core_dhcp_options.this[0].id : oci_core_vcn.this.default_dhcp_options_id

  freeform_tags = merge(local.common_freeform_tags, { "tier" = each.key })
  defined_tags  = var.defined_tags
}
