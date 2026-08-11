output "controller_private_ip" {
  value = module.controller_node.private_ip[0]
}

output "broker_private_ips" {
  value = module.broker_nodes.private_ip
}
