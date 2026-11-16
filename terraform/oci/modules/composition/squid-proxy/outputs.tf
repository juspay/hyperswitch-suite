###############################################################################
# Output contract
#
# Named after the AWS outputs consumers actually read, with OCIDs replacing
# ARNs. Deliberately ABSENT, each a recorded gap rather than a silent drop:
#
#   - nlb_dns_name / nlb_zone_id: an OCI NLB has no service-assigned DNS name,
#     only IP addresses. Every OKE workload's proxy environment variable points
#     at nlb_ip_address, which is why nlb_reserved_ip_id exists.
#   - tls_listener_arn: there is no TLS listener to have an id for. OCI's NLB
#     cannot terminate TLS at all (check sheet feature 3, verdict NONE) - see
#     tls_termination_mode below, which reports what IS terminating TLS rather
#     than leaving a reader to infer it from a missing output.
#   - target_group_arn: replaced by backend_set_name.
#   - asg_id / asg_name: replaced by instance_pool_id.
#   - iam_role_arn / instance_profile_name: OCI has no per-instance role
#     object; the fleet becomes a member of a dynamic group and policies grant
#     that group verbs. SUBSTITUTE, owned by oci/identity-model.md, not by this
#     module - which is why nothing identity-shaped is created here yet.
#   - ssh_key_parameter_name: replaced by ssh_key_vault_secret_id.
###############################################################################

output "nlb_id" {
  description = "OCID of the Network Load Balancer."
  value       = try(oci_network_load_balancer_network_load_balancer.this[0].id, null)
}

output "nlb_ip_address" {
  description = "Primary IP address of the Network Load Balancer - private when nlb_is_private is true, which it should be. Replaces AWS's nlb_dns_name. This is the address every OKE workload's HTTP_PROXY/HTTPS_PROXY points at."
  value       = try(oci_network_load_balancer_network_load_balancer.this[0].ip_addresses[0].ip_address, null)
}

output "proxy_endpoints" {
  description = "Map of protocol to endpoint, the same shape the AWS module exports. Only one entry: there is no TLS endpoint because OCI's NLB cannot terminate TLS (check sheet feature 3, verdict NONE)."
  value = {
    tcp = try("${oci_network_load_balancer_network_load_balancer.this[0].ip_addresses[0].ip_address}:${var.squid_port}", null)
  }
}

output "tls_termination_mode" {
  description = "Echo of var.tls_termination_mode, exported so a consumer can assert on it. \"none\" means NOTHING is terminating TLS on the proxy path - the OCI Network Load Balancer has no ssl_configuration of any kind and this is the honest reading of that gap, not an oversight."
  value       = var.tls_termination_mode
}

output "tls_terminated_at" {
  description = "Where TLS is terminated on the proxy path: \"squid-instance\" or \"nowhere\". Computed, not configured - the plain-language form of tls_termination_mode."
  value       = local.tls_terminated_at
}

output "backend_set_name" {
  description = "Name of the NLB backend set. Replaces AWS's target_group_arn."
  value       = try(oci_network_load_balancer_backend_set.this[0].name, null)
}

output "instance_pool_id" {
  description = "OCID of the instance pool. Replaces AWS's asg_id/asg_name."
  value       = oci_core_instance_pool.this.id
}

output "instance_configuration_id" {
  description = "OCID of the instance configuration. The launch-template-id analogue."
  value       = oci_core_instance_configuration.this.id
}

output "autoscaling_configuration_id" {
  description = "OCID of the autoscaling configuration, or null when disabled or when no policy has any rule."
  value       = try(oci_autoscaling_auto_scaling_configuration.this[0].id, null)
}

output "nsg_id" {
  description = "OCID of the module-owned, deliberately empty NSG on the Squid instances' VNICs. Replaces AWS's asg security_group_id and is the contract catalog/units/oci/security-rules writes rules into."
  value       = try(oci_core_network_security_group.instances[0].id, null)
}

output "nlb_nsg_id" {
  description = "OCID of the module-owned, deliberately empty NSG on the Network Load Balancer. AWS has no counterpart to export - an AWS NLB carries no security group - so this is new surface that makes the health-check rule expressible as an NSG-to-NSG reference instead of the AWS module's subnet-CIDR workaround."
  value       = try(oci_core_network_security_group.nlb[0].id, null)
}

output "config_bucket_name" {
  description = "Name of the bucket carrying squid.conf and the domain allowlist."
  value       = try(oci_objectstorage_bucket.config[0].name, null)
}

output "allowlist_object_name" {
  description = "Object name the allowlist was written to. Exported because the image's refresh timer must fetch exactly this name for the hot reload to work - a mismatch is silent."
  value       = var.allowlist_object_name
}

output "logs_bucket_name" {
  description = "Name of the access-log archival bucket."
  value       = try(oci_objectstorage_bucket.logs[0].name, null)
}

output "object_storage_namespace" {
  description = "Object Storage namespace both buckets live in. No AWS counterpart, but every consumer that fetches a config object needs it."
  value       = local.namespace
}

output "squid_port" {
  description = "Port Squid and the NLB listener both use."
  value       = var.squid_port
}

output "ssh_key_vault_secret_id" {
  description = "OCID of the Vault secret holding the break-glass private key. Replaces AWS's ssh_key_parameter_name. NULL when vault_id/vault_key_id were not supplied - in which case the private key exists only in Terraform state."
  value       = try(oci_vault_secret.break_glass[0].id, null)
}

output "ssh_public_key" {
  description = "Public half of the generated break-glass keypair, as authorized on the instances."
  value       = try(tls_private_key.break_glass[0].public_key_openssh, null)
}

output "availability_domain" {
  description = "Availability domain the pool places into. Exported because it is resolved from a data source, not supplied."
  value       = local.availability_domain
}
