# ============================================================================
# IAM - ROLE (IRSA)
# ============================================================================
# Trust policy scoped to the cluster-autoscaler ServiceAccount. The workload
# itself is deployed by ArgoCD using the upstream cluster-autoscaler Helm
# chart, which annotates its ServiceAccount with this role ARN.
resource "aws_iam_role" "this" {
  name                 = local.role_name
  description          = var.role_description
  path                 = var.role_path
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${data.aws_iam_openid_connect_provider.eks.url}:aud" = "sts.amazonaws.com"
            "${data.aws_iam_openid_connect_provider.eks.url}:sub" = local.service_account_subject
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# ============================================================================
# IAM - CLUSTER AUTOSCALER POLICY
# ============================================================================
# Discovery permissions are cluster-wide, while the scaling actions are
# restricted to Auto Scaling groups tagged for this cluster.
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "ClusterAutoscalerDiscovery"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ClusterAutoscalerScaling"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${local.name_prefix}-policy"
  description = "Permissions for the Cluster Autoscaler to scale node groups of ${var.eks_cluster_name}"
  path        = var.role_path
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# ============================================================================
# IAM - ADDITIONAL POLICY ATTACHMENTS
# ============================================================================
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
