output "hyperswitch_namespace" {
  value = try(kubernetes_namespace_v1.hyperswitch[0].metadata[0].name, null)
}

output "cluster_autoscaler_dynamic_group_name" {
  value = try(oci_identity_dynamic_group.cluster_autoscaler[0].name, null)
}
