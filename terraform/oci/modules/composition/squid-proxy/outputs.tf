output "instance_pool_id" {
  value = oci_core_instance_pool.squid.id
}

output "nlb_id" {
  value = try(oci_network_load_balancer_network_load_balancer.squid[0].id, null)
}

output "nlb_ip_addresses" {
  value = try(oci_network_load_balancer_network_load_balancer.squid[0].ip_addresses, null)
}
