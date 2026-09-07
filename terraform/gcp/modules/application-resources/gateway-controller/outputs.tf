output "ssl_policy_id" {
  description = "ID of the SSL policy, if created"
  value       = var.create_ssl_policy ? google_compute_ssl_policy.gateway[0].id : null
}

output "ssl_policy_name" {
  description = "Name of the SSL policy - this is the value to put in a GKE FrontendConfig's spec.sslPolicy to actually attach it to a load balancer"
  value       = var.create_ssl_policy ? google_compute_ssl_policy.gateway[0].name : null
}

output "ssl_policy_self_link" {
  description = "Self-link of the SSL policy, for callers attaching it to a target proxy directly rather than through a FrontendConfig"
  value       = var.create_ssl_policy ? google_compute_ssl_policy.gateway[0].self_link : null

  # Lives here rather than in a validation block: Terraform 1.5 cannot
  # cross-reference variables inside one.
  precondition {
    condition = !var.create_service_account || (
      var.cluster_name != null &&
      var.cluster_location != null &&
      var.cluster_endpoint != null &&
      var.cluster_ca_certificate != null
    )
    error_message = "create_service_account = true requires cluster_name, cluster_location, cluster_endpoint and cluster_ca_certificate to all be set."
  }
}

output "service_account_email" {
  description = "Email of the controller-adjacent service account, if created"
  value       = var.create_service_account ? module.workload_identity[0].gcp_service_account_email : null
}

output "k8s_service_account_name" {
  description = "Bound Kubernetes service account name, if created"
  value       = var.create_service_account ? module.workload_identity[0].k8s_service_account_name : null
}
