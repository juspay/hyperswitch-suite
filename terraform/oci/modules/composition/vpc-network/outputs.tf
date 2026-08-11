output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "vcn_cidr_blocks" {
  value = oci_core_vcn.this.cidr_blocks
}

output "internet_gateway_id" {
  value = try(oci_core_internet_gateway.this[0].id, null)
}

output "nat_gateway_id" {
  value = try(oci_core_nat_gateway.this[0].id, null)
}

output "service_gateway_id" {
  value = try(oci_core_service_gateway.this[0].id, null)
}

output "public_route_table_id" {
  value = try(oci_core_route_table.public[0].id, null)
}

output "private_route_table_id" {
  value = try(oci_core_route_table.private[0].id, null)
}

output "isolated_route_table_id" {
  value = try(oci_core_route_table.isolated[0].id, null)
}

output "subnet_ids" {
  description = "Map of tier name -> subnet OCID"
  value       = { for k, v in oci_core_subnet.tiers : k => v.id }
}

output "subnet_cidrs" {
  description = "Map of tier name -> subnet CIDR"
  value       = { for k, v in oci_core_subnet.tiers : k => v.cidr_block }
}
