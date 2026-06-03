terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }
}

variable "origin_access_controls" {
  description = "Map of OAC configurations"
  type = map(object({
    name                              = string
    description                       = optional(string, "")
    origin_access_control_origin_type = optional(string, "s3")
    signing_behavior                  = optional(string, "always")
    signing_protocol                  = optional(string, "sigv4")
  }))
  default = {}
}

resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_access_controls

  name                              = each.value.name
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_access_control_origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = each.value.signing_protocol
}

output "oac_ids" {
  description = "Map of OAC names to IDs"
  value = {
    for k, v in aws_cloudfront_origin_access_control.this : k => v.id
  }
}

output "oac_arns" {
  description = "Map of OAC names to ARNs"
  value = {
    for k, v in aws_cloudfront_origin_access_control.this : k => v.arn
  }
}
