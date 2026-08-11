output "cluster_id" {
  value = module.oke.cluster_id
}

output "cluster_endpoints" {
  value = module.oke.cluster_endpoints
}

output "cluster_ca_cert" {
  value     = module.oke.cluster_ca_cert
  sensitive = true
}

output "worker_pool_ids" {
  value = module.oke.worker_pool_ids
}

output "oidc_discovery_endpoint" {
  value = module.oke.cluster_oidc_discovery_endpoint
}
