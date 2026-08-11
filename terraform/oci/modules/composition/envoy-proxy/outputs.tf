output "instance_pool_id" {
  value = oci_core_instance_pool.envoy.id
}

output "load_balancer_id" {
  value = try(oci_load_balancer_load_balancer.envoy[0].id, null)
}

output "load_balancer_ip" {
  value = try(oci_load_balancer_load_balancer.envoy[0].ip_address_details, null)
}
