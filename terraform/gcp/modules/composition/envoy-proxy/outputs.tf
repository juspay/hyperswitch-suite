output "load_balancer_ip_address" {
  description = "External IP address of the Envoy load balancer"
  value       = module.load_balancer.external_ip
}

output "instance_groups" {
  description = "Map of deployment name to that deployment's managed instance group self-link"
  value       = { for name, mig in module.proxy_mig : name => mig.instance_group }
}

output "deployment_weights" {
  description = "Map of deployment name to its configured load-balancer traffic weight"
  value       = { for name, d in var.deployments : name => d.weight }
}

output "url_map_id" {
  description = "ID of the module-managed URL map handling weighted deployment routing and listener_rules"
  value       = google_compute_url_map.envoy.id
}

output "config_bucket_name" {
  description = "Name of the config bucket"
  value       = module.config_bucket.name
}

output "log_bucket_name" {
  description = "Name of the access-log bucket"
  value       = module.log_bucket.name
}

output "service_account_email" {
  description = "Email of the proxy fleet's service account"
  value       = module.service_account.email
}

output "cloud_armor_policy_id" {
  description = "ID of the Cloud Armor policy, if enabled"
  value       = var.enable_cloud_armor ? module.cloud_armor[0].policy.id : null
}

output "mtls_server_tls_policy_id" {
  description = "ID of the mTLS Server TLS Policy, if enabled"
  value       = var.enable_mtls_listener ? google_network_security_server_tls_policy.mtls[0].id : null
}
