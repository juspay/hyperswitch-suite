# Output contract.

output "load_balancer_id" {
  description = "OCID of the load balancer. This is the value oci_waf_web_app_firewall and any external DNS/steering-policy unit needs."
  value       = local.load_balancer_id
}

output "lb_ip_address" {
  description = "Primary IP address of the load balancer, read from ip_address_details (the flat ip_addresses attribute is deprecated in oracle/oci 9.0.0). Replaces AWS's lb_dns_name - OCI load balancers are consumed by IP, and a DNS A record at this address (or at the Reserved Public IP pinning it) is what fronts the platform."
  value       = try(oci_load_balancer_load_balancer.this[0].ip_address_details[0].ip_address, null)
}

output "lb_ip_address_details" {
  description = "Full ip_address_details list from the load balancer: address, is_public and the reserved-IP association if one exists."
  value       = try(oci_load_balancer_load_balancer.this[0].ip_address_details, [])
}

output "backend_set_names" {
  description = "Names of the backend sets this module created. Replaces AWS's target_group_arns. One entry in shared_backend_set mode, one per deployment in listener_cutover mode."
  value       = [for bs in oci_load_balancer_backend_set.this : bs.name]
}

output "default_backend_set_name" {
  description = "Backend set the listeners forward to by default. In listener_cutover mode this is the active deployment's set and is the single value a blue/green flip changes."
  value       = var.create_lb ? local.default_backend_set_name : null
}

output "instance_pool_ids" {
  description = "Map of deployment key to instance pool OCID. Replaces AWS's asg_ids/asg_names."
  value       = { for k, p in oci_core_instance_pool.this : k => p.id }
}

output "instance_configuration_ids" {
  description = "Map of deployment key to instance configuration OCID. The launch-template-id analogue."
  value       = { for k, c in oci_core_instance_configuration.this : k => c.id }
}

output "autoscaling_configuration_ids" {
  description = "Map of deployment key to autoscaling configuration OCID. Empty when enable_autoscaling = false or no policy has any rule."
  value       = { for k, a in oci_autoscaling_auto_scaling_configuration.this : k => a.id }
}

output "deployment_weights" {
  description = <<-EOT
    Map of deployment key to its declared weight AND the pool size that weight
    was translated into. Both are exported because they are NOT the same thing
    on OCI: weight is what the caller asked for, size is the instance count
    that actually determines the traffic share in shared_backend_set mode.
    Read `effective_share_pct` as the real split, not `weight`.
  EOT
  value = {
    for k, d in local.deployments : k => {
      weight              = d.weight
      initial_size        = d.min_replicas
      max_size            = d.max_replicas
      effective_share_pct = 100 * d.min_replicas / sum([for x in values(local.deployments) : x.min_replicas])
      backend_set         = local.pool_backend_set[k]
      is_preemptible      = d.is_preemptible
    }
  }
}

output "nsg_id" {
  description = "OCID of the module-owned, deliberately empty NSG on the Envoy instances' VNICs. Replaces AWS's asg security_group_id and is the contract catalog/units/oci/security-rules writes rules into."
  value       = try(oci_core_network_security_group.instances[0].id, null)
}

output "lb_nsg_id" {
  description = "OCID of the module-owned, deliberately empty NSG on the load balancer. Replaces AWS's lb security_group_id."
  value       = try(oci_core_network_security_group.lb[0].id, null)
}

output "config_bucket_name" {
  description = "Name of the Object Storage bucket carrying envoy.yaml. Addressed as namespace + name, not as a globally unique name."
  value       = try(oci_objectstorage_bucket.config[0].name, null)
}

output "logs_bucket_name" {
  description = "Name of the access-log archival bucket."
  value       = try(oci_objectstorage_bucket.logs[0].name, null)
}

output "object_storage_namespace" {
  description = "Object Storage namespace both buckets live in. No AWS counterpart - S3 has no namespace concept - but every consumer that fetches a config object needs it."
  value       = local.namespace
}

output "waf_id" {
  description = "OCID of the WAF attachment, or null when enable_waf is false or no policy was supplied. Note this is the ATTACHMENT; the policy itself is owned elsewhere, mirroring the AWS module."
  value       = try(oci_waf_web_app_firewall.this[0].id, null)
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
  description = "Availability domain the pool places into. Exported because it is resolved from a data source, not supplied, and a consumer placing an adjacent resource needs the same value."
  value       = local.availability_domain
}
