locals {
  create = var.create
}

resource "aws_cloudfront_function" "this" {
  for_each = local.create ? var.cloudfront_functions : {}

  name    = each.value.name
  runtime = each.value.runtime
  comment = lookup(each.value, "comment", null)
  code    = each.value.code
  publish = lookup(each.value, "publish", true)
}
