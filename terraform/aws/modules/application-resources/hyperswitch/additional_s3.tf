# One additional policy for all buckets keeps role policy attachments bounded.
# Bucket actions use the bucket ARN; object actions use only that bucket's keys.
resource "aws_iam_policy" "additional_s3_buckets" {
  count = length(var.additional_s3_buckets) > 0 ? 1 : 0

  name = "${local.name_prefix}-additional-s3-buckets-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      for bucket in values(var.additional_s3_buckets) : concat(
        length(bucket.bucket_actions) > 0 ? [{
          Effect   = "Allow"
          Action   = bucket.bucket_actions
          Resource = bucket.bucket_arn
        }] : [],
        length(bucket.object_actions) > 0 ? [{
          Effect   = "Allow"
          Action   = bucket.object_actions
          Resource = "${bucket.bucket_arn}/*"
        }] : [],
      )
    ])
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "additional_s3_buckets" {
  count = length(var.additional_s3_buckets) > 0 ? 1 : 0

  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.additional_s3_buckets[0].arn
}
