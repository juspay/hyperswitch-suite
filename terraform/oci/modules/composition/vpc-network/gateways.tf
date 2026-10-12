# Internet gateway - limit 1 per VCN, not increasable.

resource "oci_core_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# NAT gateway - regional, VCN-scoped, hard limit of 1 per VCN, so there is ONE
# egress IP rather than one per AZ. `public_ip_id` pins the egress address to a
# reserved public IP that survives gateway replacement.

resource "oci_core_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-natgw"

  public_ip_id = var.nat_reserved_public_ip_id

  # Kill switch: blocks all traffic through the gateway without destroying it
  # or releasing the reserved IP.
  block_traffic = var.nat_block_traffic

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# Service gateway - one regional gateway replaces the AWS module's whole
# vpc-endpoints.tf. A route-based target with no VNIC, so there is nothing to
# attach a security group to (AWS's vpc_endpoint_security_group_id inverts to a
# per-consumer NSG egress rule to SERVICE_CIDR_BLOCK in composition/security-
# rules) and no customer-addressable PrivateLink equivalent (`custom_interface_
# vpc_endpoints` is deliberately absent). OCI exposes service CIDR LABELS, not
# service names, so per-service granularity is lost.
#
# See locals.tf for why the two service CIDR labels are mutually exclusive.

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
