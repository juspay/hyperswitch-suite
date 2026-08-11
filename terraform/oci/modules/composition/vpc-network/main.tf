locals {
  name_prefix = "${var.environment}-${var.project_name}"

  common_tags = var.freeform_tags

  public_tiers   = { for k, v in var.subnet_tiers : k => v if v.is_public }
  nat_tiers      = { for k, v in var.subnet_tiers : k => v if !v.is_public && v.route_via == "nat" }
  isolated_tiers = { for k, v in var.subnet_tiers : k => v if !v.is_public && v.route_via == "none" }
}

# ============================================================================
# VCN
# ============================================================================
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
  cidr_blocks    = var.vcn_cidr_blocks
  dns_label      = var.vcn_dns_label

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Internet Gateway (equivalent to AWS Internet Gateway)
# ============================================================================
resource "oci_core_internet_gateway" "this" {
  count = var.enable_internet_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# NAT Gateway (equivalent to AWS NAT Gateway)
# ============================================================================
resource "oci_core_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-nat"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Service Gateway (private access to OCI services - closest analog to an
# AWS S3 Gateway VPC Endpoint, used by the "data-stack" tier in the AWS module)
# ============================================================================
data "oci_core_services" "all" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  count = var.enable_service_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-sgw"

  services {
    service_id = data.oci_core_services.all.services[0].id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Route Tables
# ============================================================================

# Public route table: default route to Internet Gateway
resource "oci_core_route_table" "public" {
  count = var.enable_internet_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this[0].id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Private route table: default route to NAT Gateway, OCI services via Service Gateway
resource "oci_core_route_table" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-private-rt"

  dynamic "route_rules" {
    for_each = var.enable_service_gateway ? [1] : []
    content {
      destination       = data.oci_core_services.all.services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      network_entity_id = oci_core_service_gateway.this[0].id
    }
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this[0].id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Isolated route table: no default route out (mirrors AWS "private-isolated" tiers
# like database/locker-database/elasticache which have no NAT route), OCI services
# only, via Service Gateway
resource "oci_core_route_table" "isolated" {
  count = length(local.isolated_tiers) > 0 && var.enable_service_gateway ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-isolated-rt"

  route_rules {
    destination       = data.oci_core_services.all.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this[0].id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Default Security List per subnet
# ============================================================================
# Security enforcement is delegated to Network Security Groups attached by
# each consuming module (cassandra, database, eks, etc) and by the
# security-rules module for cross-module rules - mirroring how the AWS
# module leaves subnet-level security groups to be created elsewhere.
# The subnet-level security list here is a permissive baseline (all traffic
# within the VCN, all egress) so NSGs are the actual enforcement point.
resource "oci_core_security_list" "default" {
  for_each = var.subnet_tiers

  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.name_prefix}-${each.key}-default-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = var.vcn_cidr_blocks[0]
    protocol = "all"
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Subnets (one regional subnet per tier)
# ============================================================================
resource "oci_core_subnet" "tiers" {
  for_each = var.subnet_tiers

  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${local.name_prefix}-${each.key}"
  cidr_block                 = each.value.cidr_block
  dns_label                  = each.value.dns_label
  prohibit_public_ip_on_vnic = !each.value.is_public

  route_table_id = (
    each.value.is_public ? oci_core_route_table.public[0].id :
    each.value.route_via == "nat" ? oci_core_route_table.private[0].id :
    length(local.isolated_tiers) > 0 && var.enable_service_gateway ? oci_core_route_table.isolated[0].id :
    oci_core_vcn.this.default_route_table_id
  )

  security_list_ids = [oci_core_security_list.default[each.key].id]

  freeform_tags = merge(var.freeform_tags, each.value.freeform_tags)
  defined_tags  = var.defined_tags
}
