terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }
}

variable "origin_access_identities" {
  description = "Map of OAI configurations"
  type = map(object({
    comment = optional(string, "")
  }))
  default = {}
}

resource "aws_cloudfront_origin_access_identity" "this" {
  for_each = var.origin_access_identities

  comment = each.value.comment
}

output "oai_ids" {
  description = "Map of OAI names to IDs"
  value = {
    for k, v in aws_cloudfront_origin_access_identity.this : k => v.id
  }
}

output "oai_canonical_user_ids" {
  description = "Map of OAI names to canonical user IDs"
  value = {
    for k, v in aws_cloudfront_origin_access_identity.this : k => v.s3_canonical_user_id
  }
}

output "oai_iam_arns" {
  description = "Map of OAI names to IAM ARNs"
  value = {
    for k, v in aws_cloudfront_origin_access_identity.this : k => v.iam_arn
  }
}
