# Create assume role policy from service identifiers if custom policy not provided
locals {
  assume_role_policy = var.assume_role_policy != null ? var.assume_role_policy : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.service_identifiers
        }
      }
    ]
  })
}

resource "aws_iam_role" "this" {
  name                 = var.name
  description          = var.description
  assume_role_policy   = local.assume_role_policy
  max_session_duration = var.max_session_duration
  path                 = var.path

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Create inline policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

# Create instance profile if requested
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.name
  role = aws_iam_role.this.name
  path = var.path

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}
