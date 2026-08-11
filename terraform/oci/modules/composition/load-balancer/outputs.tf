output "load_balancer_id" {
  value = try(oci_load_balancer_load_balancer.this[0].id, null)
}

output "load_balancer_ip" {
  value = try(oci_load_balancer_load_balancer.this[0].ip_address_details, null)
}

output "nsg_id" {
  value = oci_core_network_security_group.this.id
}

output "dns_zone_id" {
  value = try(oci_dns_zone.this[0].id, null)
}
