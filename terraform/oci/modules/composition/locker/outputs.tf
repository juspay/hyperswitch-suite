output "instance_private_ips" {
  value = module.locker_instances.private_ip
}

output "load_balancer_id" {
  value = oci_load_balancer_load_balancer.locker.id
}

output "database_id" {
  value = try(module.database[0].db_system_id, null)
}
