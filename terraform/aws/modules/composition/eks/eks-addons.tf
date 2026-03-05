# =============================================================================
# EKS Composition Module - EKS Addons
# =============================================================================

# -----------------------------------------------------------------------------
# Local values for addon sequencing
# -----------------------------------------------------------------------------
locals {
  # Addons that MUST be created BEFORE node groups
  # These are critical for node bootstrapping and networking
  addons_before_nodes = ["vpc-cni", "kube-proxy"]

  # Map service account role short names to module outputs
  service_account_role_map = {
    "ebs_csi" = module.ebs_csi_irsa.iam_role_arn
  }
}

# -----------------------------------------------------------------------------
# EKS Addons - Created BEFORE node groups
# vpc-cni and kube-proxy are required for proper node bootstrapping
# -----------------------------------------------------------------------------
resource "aws_eks_addon" "before_nodes" {
  for_each = {
    for k, v in var.eks_addons : k => v
    if contains(local.addons_before_nodes, k)
  }

  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Service account role if specified
  service_account_role_arn = each.value.service_account_role != null ? lookup(
    local.service_account_role_map,
    each.value.service_account_role,
    each.value.service_account_role
  ) : null

  # Must be created after cluster is ready
  depends_on = [module.eks]
}

# -----------------------------------------------------------------------------
# EKS Addons - Created AFTER node groups
# coredns, ebs-csi-driver, snapshot-controller, metrics-server
# These require compute nodes to be running
# -----------------------------------------------------------------------------
resource "aws_eks_addon" "after_nodes" {
  for_each = {
    for k, v in var.eks_addons : k => v
    if !contains(local.addons_before_nodes, k)
  }

  cluster_name                = module.eks.cluster_name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Service account role if specified
  service_account_role_arn = each.value.service_account_role != null ? lookup(
    local.service_account_role_map,
    each.value.service_account_role,
    each.value.service_account_role
  ) : null

  # Must be created after cluster and node groups are ready
  depends_on = [
    module.eks,
    aws_eks_node_group.custom_nodes
  ]
}
