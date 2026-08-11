output "db_system_id" {
  value = oci_psql_db_system.this.id
}

output "primary_endpoint_ip" {
  value = try(oci_psql_db_system.this.network_details[0].primary_db_endpoint_private_ip, null)
}

output "instances" {
  value = oci_psql_db_system.this.instances
}
