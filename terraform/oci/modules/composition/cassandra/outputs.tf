output "instance_ids" {
  value = module.cassandra_nodes.instance_id
}

output "private_ips" {
  value = module.cassandra_nodes.private_ip
}

output "nsg_id" {
  value = oci_core_network_security_group.cassandra.id
}

output "dynamic_group_name" {
  value = oci_identity_dynamic_group.cassandra.name
}
