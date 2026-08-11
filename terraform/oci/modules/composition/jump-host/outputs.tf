output "instance_private_ip" {
  value = module.jump_instance.private_ip[0]
}

output "nsg_id" {
  value = oci_core_network_security_group.jump_host.id
}
