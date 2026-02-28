# ============================================================================
# IAM Policies
# ============================================================================

resource "aws_iam_policy" "this" {
  for_each = var.create ? var.policies : {}

  name        = each.value.name
  description = each.value.description
  policy      = each.value.policy
  path        = each.value.path

  tags = merge(var.common_tags, each.value.tags)
}