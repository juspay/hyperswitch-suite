output "keeper_private_ips" {
  value = try(module.keeper_nodes[0].private_ip, [])
}

output "server_private_ips" {
  value = module.server_nodes.private_ip
}

output "load_balancer_id" {
  value = oci_load_balancer_load_balancer.clickhouse.id
}

output "load_balancer_ip" {
  value = oci_load_balancer_load_balancer.clickhouse.ip_address_details
}
