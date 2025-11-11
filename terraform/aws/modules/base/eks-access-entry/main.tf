resource "aws_eks_access_entry" "this" {
  cluster_name      = var.cluster_name
  principal_arn     = var.principal_arn
  kubernetes_groups = var.kubernetes_groups
  type              = var.type
  user_name         = var.user_name

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${var.principal_arn}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_access_policy_association" "this" {
  for_each = { for idx, policy in var.access_policies : idx => policy }

  cluster_name  = var.cluster_name
  principal_arn = var.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope_type
    namespaces = each.value.access_scope_namespaces
  }

  depends_on = [aws_eks_access_entry.this]
}
