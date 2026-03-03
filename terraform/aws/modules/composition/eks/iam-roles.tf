# =============================================================================
# EKS Composition Module - IAM Roles (ArgoCD Cross-Account)
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role for ArgoCD Cross-Account Access
# Allows ArgoCD from another AWS account to access this EKS cluster
# -----------------------------------------------------------------------------
resource "aws_iam_role" "argocd_cross_account" {
  count = var.create_argocd_cross_account_role ? 1 : 0

  name = "${var.environment}-${var.project_name}-argocd-cross-account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.argocd_assume_role_principal_arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# -----------------------------------------------------------------------------
# IAM Policy for EKS Access
# Grants permissions to describe and interact with the EKS cluster
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "argocd_eks_access" {
  count = var.create_argocd_cross_account_role ? 1 : 0

  name        = "${var.environment}-${var.project_name}-argocd-eks-access"
  description = "Policy for ArgoCD cross-account EKS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeFargateProfile",
          "eks:ListFargateProfiles",
          "eks:DescribeUpdate",
          "eks:ListUpdates"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Attach EKS access policy to ArgoCD role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "argocd_eks_access" {
  count = var.create_argocd_cross_account_role ? 1 : 0

  role       = aws_iam_role.argocd_cross_account[0].name
  policy_arn = aws_iam_policy.argocd_eks_access[0].arn
}
