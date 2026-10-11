output "cloudfront_functions" {
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => {
      id     = fn.id
      name   = fn.name
      arn    = fn.arn
      etag   = fn.etag
      status = fn.status
    }
  } : {}
}

output "cloudfront_function_ids" {
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => fn.id
  } : {}
}

output "cloudfront_function_arns" {
  value = local.create ? {
    for fn in aws_cloudfront_function.this :
    fn.name => fn.arn
  } : {}
}
