###############################################################################
# The VCN itself
###############################################################################

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id

  # cidr_blocks (plural) is the current attribute; the singular cidr_block is
  # deprecated and migrating from it is one-way. AWS's vpc_cidr plus its
  # aws_vpc_ipv4_cidr_block_association secondaries are one list here.
  cidr_blocks = var.vcn_cidr_blocks

  display_name = var.vcn_display_name

  # There is no OCI counterpart to enable_dns_hostnames / enable_dns_support:
  # the VCN resolver is always on and this label is what makes instances
  # resolvable as <host>.<subnet-label>.<vcn-label>.oraclevcn.com. Not
  # updatable - it forces replacement, so it is set from day one.
  dns_label = local.vcn_dns_label

  is_ipv6enabled = var.enable_ipv6

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

###############################################################################
# Default resource lockdown
#
# The AWS module locks down aws_default_network_acl / _security_group /
# _route_table largely as hygiene. On OCI this is a PREREQUISITE, not
# hardening (check sheet section 4.8, ../network-security-model.md section 3.3):
#
#   - a new VCN's default security list ships with STATEFUL SSH 22 ingress and
#     ALLOW-ALL EGRESS;
#   - any subnet that omits security_list_ids inherits it;
#   - security-list rules UNION with NSG rules ("a packet is allowed if any
#     rule in any of the relevant lists and groups allows the traffic").
#
# So leaving it populated silently defeats every egress restriction the
# NSG-only model depends on. A non-empty default security list is a release
# blocker, not a lint finding. Zero rule blocks below is the whole point of
# this resource - do not add any.
###############################################################################

resource "oci_core_default_security_list" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_security_list_id
  display_name               = "${local.name_prefix}-default-security-list-empty"

  # Intentionally no ingress_security_rules and no egress_security_rules.

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# The default route table is emptied too. Every subnet this module creates is
# explicitly associated with a named table from the catalogue, so anything
# landing on the default table is unintended and should have no route.
resource "oci_core_default_route_table" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_route_table_id
  display_name               = "${local.name_prefix}-default-route-table-empty"

  # Intentionally no route_rules.

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

###############################################################################
# DHCP options
#
# PARTIAL parity - see the variables.tf header. No NTP option type exists on
# OCI, search_domain_names takes one entry, custom_dns_servers is capped at 3.
###############################################################################

resource "oci_core_default_dhcp_options" "this" {
  manage_default_resource_id = oci_core_vcn.this.default_dhcp_options_id
  display_name               = "${local.name_prefix}-default-dhcp-options"

  options {
    type               = "DomainNameServer"
    server_type        = var.dhcp_dns_server_type
    custom_dns_servers = var.dhcp_dns_server_type == "CustomDnsServer" ? var.dhcp_custom_dns_servers : []
  }

  dynamic "options" {
    for_each = var.dhcp_search_domain_name == null ? [] : [var.dhcp_search_domain_name]
    content {
      type                = "SearchDomain"
      search_domain_names = [options.value]
    }
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_dhcp_options" "this" {
  count = var.create_dhcp_options ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-dhcp-options"

  options {
    type               = "DomainNameServer"
    server_type        = var.dhcp_dns_server_type
    custom_dns_servers = var.dhcp_dns_server_type == "CustomDnsServer" ? var.dhcp_custom_dns_servers : []
  }

  dynamic "options" {
    for_each = var.dhcp_search_domain_name == null ? [] : [var.dhcp_search_domain_name]
    content {
      type                = "SearchDomain"
      search_domain_names = [options.value]
    }
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}
