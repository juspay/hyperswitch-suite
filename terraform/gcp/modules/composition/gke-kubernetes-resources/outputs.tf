output "rbac_role_names" {
  description = "Names of created default RBAC cluster roles"
  value = compact([
    try(kubernetes_cluster_role_v1.developer[0].metadata[0].name, ""),
    try(kubernetes_cluster_role_v1.readonly[0].metadata[0].name, ""),
    try(kubernetes_cluster_role_v1.cicd[0].metadata[0].name, ""),
  ])
}

output "default_storage_class_name" {
  description = "Name of the default storage class, if created"
  value       = var.create_default_storage_class ? kubernetes_storage_class_v1.pd_balanced[0].metadata[0].name : null
}

output "hyperswitch_namespace" {
  description = "Namespace the Hyperswitch Helm release was deployed into, if enabled"
  value       = var.enable_helm_deployments ? kubernetes_namespace_v1.hyperswitch[0].metadata[0].name : null
}

output "hyperswitch_release_status" {
  description = "Status of the Hyperswitch Helm release, if enabled"
  value       = var.enable_helm_deployments ? helm_release.hyperswitch_stack[0].status : null
}
