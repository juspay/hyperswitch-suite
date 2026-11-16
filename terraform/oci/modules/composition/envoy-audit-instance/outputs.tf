output "instance_id" {
  description = "OCID of the standalone audit instance."
  value       = oci_core_instance.this.id
}

output "instance_name" {
  description = "Display name of the audit instance."
  value       = oci_core_instance.this.display_name
}

output "private_ip" {
  description = "Private IP of the audit instance - the address the security team SSHs to over the VPN. No public IP exists."
  value       = oci_core_instance.this.private_ip
}

output "nsg_id" {
  description = "OCID of the module-owned NSG carrying the SSH-from-VPN ingress rules."
  value       = try(oci_core_network_security_group.this[0].id, null)
}

output "availability_domain" {
  description = "Availability domain the instance was created in. Exported because it is resolved from a data source, not supplied."
  value       = local.availability_domain
}