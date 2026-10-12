# NO `oci_identity_policy` and no Kubernetes provider. The grant lands in the
# shared oke-workload-identity object via policy_statements; nothing on the
# cluster is annotated. CLIENT-SIDE CAVEAT: on OCI ArgoCD needs execProviderConfig
# plus a custom image containing the OCI CLI - without those, updating the
# Terraform plans clean and deploys nothing.

# Cross-compartment reach for deploy targets outside the cluster's own subtree.
# Namespace-granular only, so it widens reach and never narrows it; the
# service-account condition in the statements stays the sole fine-grained
# control. Off by default because the recommended layout puts targets inside the
# subtree.
resource "oci_containerengine_cluster_workload_mapping" "targets" {
  for_each = local.workload_mapping_keys

  cluster_id            = each.value.cluster_id
  namespace             = each.value.namespace
  mapped_compartment_id = each.value.target

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}
