# Outputs

output "keeper_instance_ids" {
  description = "OCIDs of the ClickHouse Keeper instances. Unchanged name."
  value       = oci_core_instance.keeper[*].id
}

output "server_instance_ids" {
  description = "OCIDs of the ClickHouse server instances. Unchanged name."
  value       = oci_core_instance.server[*].id
}

output "keeper_private_ips" {
  description = <<-EOT
    Reserved private IP addresses of the Keepers. Replaces keeper_private_ips AND
    keeper_eni_private_ips, distinct on AWS only because the ENI was a separate
    object. Sourced from oci_core_private_ip - these survive instance replacement,
    the instance's own primary IP does not.
  EOT
  value       = local.keeper_reserved_ips
}

output "server_private_ips" {
  description = "Reserved private IP addresses of the servers. Replaces server_private_ips and server_eni_private_ips."
  value       = local.server_reserved_ips
}

output "keeper_instance_primary_ips" {
  description = "Primary (ephemeral) VNIC IPs of the Keepers. Diagnostic only - do NOT build cluster configuration from these."
  value       = oci_core_instance.keeper[*].private_ip
}

output "server_instance_primary_ips" {
  description = "Primary (ephemeral) VNIC IPs of the servers. These ARE what the load balancer registers as backends - see load-balancer.tf for why."
  value       = oci_core_instance.server[*].private_ip
}

output "keeper_reserved_private_ip_ids" {
  description = "OCIDs of the Keepers' reserved oci_core_private_ip objects. Closest analogue of keeper_eni_ids; what a replacement runbook re-points."
  value       = oci_core_private_ip.keeper[*].id
}

output "server_reserved_private_ip_ids" {
  description = "OCIDs of the servers' reserved oci_core_private_ip objects. Replaces server_eni_ids."
  value       = oci_core_private_ip.server[*].id
}

output "keeper_nsg_id" {
  description = "OCID of the module-owned, empty Keeper NSG. Replaces keeper_security_group_id. The contract composition/security-rules writes rules into."
  value       = try(oci_core_network_security_group.keeper[0].id, null)
}

output "server_nsg_id" {
  description = "OCID of the module-owned, empty server NSG. Replaces server_security_group_id and, because the load balancer joins this NSG rather than owning one, also alb_security_group_id."
  value       = try(oci_core_network_security_group.server[0].id, null)
}

output "cluster_info" {
  description = "Cluster topology summary. Same role as the AWS output of the same name; the peer address fields come from reserved private IPs."
  value = {
    keeper_count    = var.keeper_count
    server_count    = var.server_count
    keeper_ips      = local.keeper_reserved_ips
    server_ips      = local.server_reserved_ips
    clickhouse_port = var.clickhouse_port
  }
}

output "load_balancer_id" {
  description = "OCID of the internal load balancer."
  value       = oci_load_balancer_load_balancer.this.id
}

output "load_balancer_ip" {
  description = <<-EOT
    Private IP address of the internal load balancer. Replaces alb_dns_name.

    NOTE THE SHAPE CHANGE: AWS handed back a DNS name; an OCI private load
    balancer exposes an IP. Whether a companion DNS record is still wanted, and
    through which OCI DNS mechanism, is check sheet open question 9.4 and is
    cloud-dns's problem, not this module's.
  EOT
  # ip_address_details is the supported replacement for the deprecated ip_addresses.
  value = try(oci_load_balancer_load_balancer.this.ip_address_details[0].ip_address, null)
}

output "load_balancer_ip_addresses" {
  description = "All IP addresses assigned to the load balancer, with their public/private flag."
  value       = oci_load_balancer_load_balancer.this.ip_address_details
}

output "backend_set_name" {
  description = "Load balancer backend-set name. Replaces alb_listener_arns - OCI has no ARN, so the backend-set and listener NAMES are the addressable identifiers."
  value       = oci_load_balancer_backend_set.servers.name
}

output "listener_names" {
  description = "Names of the configured listeners."
  value       = [for l in oci_load_balancer_listener.this : l.name]
}

output "clickhouse_port" {
  description = "ClickHouse HTTP port. Unchanged."
  value       = var.clickhouse_port
}

output "key_pair_name" {
  description = "Logical key-pair name. Unchanged in name only - OCI has no key-pair object, so key_pair_id has no counterpart and is dropped."
  value       = var.create_key_pair ? local.key_pair_name : var.key_name
}

output "ssh_private_key_vault_secret_id" {
  description = "OCID of the Vault secret holding the generated SSH private key. Replaces private_key_ssm_parameter."
  value       = try(oci_vault_secret.ssh_private_key[0].id, null)
}

# No iam_role / instance_profile outputs - none of those objects exist on OCI.
output "dynamic_group_id" {
  description = "OCID of the dynamic group matching this fleet."
  value       = try(oci_identity_dynamic_group.nodes[0].id, null)
}

output "dynamic_group_name" {
  description = "Dynamic group name. Policy statements reference a dynamic group by NAME, not OCID."
  value       = try(oci_identity_dynamic_group.nodes[0].name, null)
}

output "policy_id" {
  description = "OCID of the policy granting the dynamic group its permissions."
  value       = try(oci_identity_policy.nodes[0].id, null)
}

output "availability_domain" {
  description = "Availability domain both tiers were placed in. Exactly one exists in ap-mumbai-1."
  value       = local.availability_domain
}

output "fault_domains" {
  description = "Fault domains the tiers were spread across - the only in-region fault isolation available."
  value       = local.fault_domains
}
