output "cluster_name" {
  value = module.hyperswitch.cluster_name
}

output "cluster_endpoint" {
  value = module.hyperswitch.cluster_endpoint
}

output "vpc_id" {
  value = module.hyperswitch.vpc_id
}

output "configure_kubectl" {
  value = module.hyperswitch.configure_kubectl
}

output "port_forward_commands" {
  value = module.hyperswitch.port_forward_commands
}
