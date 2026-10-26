# ============================================================================
# Data Sources
# ============================================================================

data "aws_region" "current" {}

data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

# OIDC provider of the EKS cluster, used for the IRSA trust relationship.
data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
