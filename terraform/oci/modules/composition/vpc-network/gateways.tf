###############################################################################
# Internet gateway
#
# Limit 1 per VCN, documented as not increasable - the same shape as one IGW
# per VPC on AWS.
###############################################################################

resource "oci_core_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

###############################################################################
# NAT gateway
#
# SUBSTITUTE (check sheet feature 6 / section 4.1). AWS runs an appliance fleet
# - one aws_nat_gateway plus one aws_eip per availability zone, collapsible via
# single_nat_gateway. OCI's NAT gateway is a REGIONAL, VCN-scoped service with
# a hard limit of 1 per VCN, so:
#   - single_nat_gateway and nat_gateway_count have no meaning and are dropped
#     from the input surface rather than carried as dead variables;
#   - there is one egress IP, not one per AZ. Simpler to allowlist at a PSP or
#     bank, but there is no customer-controlled egress redundancy and no
#     customer-controlled egress bandwidth scaling. If NAT throughput becomes a
#     ceiling the remedy is a limit-increase request plus a second route table,
#     not a config change.
# public_ip_id plays the role aws_eip played: it pins the egress address to a
# reserved public IP that survives gateway replacement.
###############################################################################

resource "oci_core_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-natgw"

  public_ip_id = var.nat_reserved_public_ip_id

  # Kill switch with no AWS equivalent: blocks all traffic through the gateway
  # without destroying it or releasing the reserved IP.
  block_traffic = var.nat_block_traffic

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

###############################################################################
# Service gateway
#
# SUBSTITUTE (check sheet features 13 and 14 / section 4.3). This one resource
# replaces the AWS module's entire vpc-endpoints.tf:
#   - the S3 GATEWAY endpoint wired into 8 route tables becomes a service
#     gateway plus one SERVICE_CIDR_BLOCK route rule per table. Same
#     architecture: route-based, no VNIC, no per-request charge.
#   - the 19 INTERFACE endpoints (ECR, STS, SSM, KMS, Secrets Manager, ...),
#     each an ENI with an IP, a security group and an hourly charge, collapse
#     into the same single regional gateway. What is lost: per-service
#     granularity - OCI exposes service CIDR LABELS, not service names - and
#     split-horizon private DNS, so AWS's private_dns_enabled has nothing to
#     configure (hostnames stay public and are routed privately by destination
#     CIDR).
#   - there is nothing to attach a security group to, because a service gateway
#     has no VNIC. AWS's vpc_endpoint_security_group_id therefore does not
#     exist in this module's outputs (section 4.5); the equivalent control
#     inverts to a per-consumer NSG EGRESS rule with
#     destination_type = "SERVICE_CIDR_BLOCK", owned by composition/security-rules.
#   - NONE (section 4.6): custom_interface_vpc_endpoints has no counterpart at
#     all. A service gateway reaches only Oracle Services Network endpoints in
#     the SAME region; OCI has no customer-addressable PrivateLink equivalent.
#     The input is deliberately absent rather than accepted-and-ignored. The
#     two AWS prod roots that populate it (prod/us-west-2,
#     prod/eu-north-1-auto-generated) cannot migrate until each named
#     counterparty is routed through the Squid proxy, a DRG remote peering, or
#     FastConnect / Site-to-Site VPN.
#
# See locals.tf for why the two service CIDR labels are mutually exclusive.
###############################################################################

data "oci_core_services" "this" {}

resource "oci_core_service_gateway" "this" {
  count = local.service_gateway_enabled ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-sgw"

  services {
    service_id = local.selected_service_id
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = !(var.enable_service_gateway_object_storage && var.enable_service_gateway_all_services)
      error_message = "enable_service_gateway_object_storage and enable_service_gateway_all_services are mutually exclusive: Oracle documents that a service gateway can use only one service CIDR label, because Object Storage is covered by both. Set enable_service_gateway_all_services = true for the superset (recommended), or enable_service_gateway_object_storage = true for Object Storage alone."
    }

    precondition {
      condition     = local.selected_service_id != null
      error_message = "No matching service CIDR label was returned by data.oci_core_services for this region. Check the provider region setting."
    }
  }
}
