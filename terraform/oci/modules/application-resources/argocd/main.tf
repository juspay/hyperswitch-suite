# -----------------------------------------------------------------------------
# NO `oci_identity_policy`, and no Kubernetes provider.
#
# The AWS module's aws_iam_role + two policy resources have no counterpart: the
# grant is the identity, and it lands in the environment's single shared
# oke-workload-identity object via `policy_statements`. Nothing on the cluster
# is annotated - OCI needs no `eks.amazonaws.com/role-arn` equivalent, so the
# five service-account annotations in the Helm values are DELETED, not remapped.
#
# WHAT THIS MODULE CANNOT DO FOR YOU, and what will make rungs 1-5 pass while
# ArgoCD reaches nothing: the client side. On AWS, ArgoCD registers a target
# cluster with a role ARN and the AWS provider mints credentials. On OCI,
# Oracle's own approach is `execProviderConfig` in the cluster secret plus a
# CUSTOM ARGOCD IMAGE CONTAINING THE OCI CLI. That image and those cluster
# secrets are not Terraform-managed and are a hard prerequisite for any of this
# to be useful. A port that updates the Terraform and leaves the cluster secrets
# pointing at role ARNs plans clean and deploys nothing.
# -----------------------------------------------------------------------------

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
