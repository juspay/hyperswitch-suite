<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.20 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | ~> 4.2.0 |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_request_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_request_policy) | resource |
| [aws_cloudfront_response_headers_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [null_resource.cloudfront_invalidation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_response_headers_policy.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cache_policies"></a> [cache\_policies](#input\_cache\_policies) | Map of cache policies to create (keyed by policy name) | <pre>map(object({<br/>    name        = string<br/>    comment     = optional(string)<br/>    default_ttl = optional(number)<br/>    max_ttl     = optional(number)<br/>    min_ttl     = optional(number)<br/>    parameters_in_cache_key_and_forwarded_to_origin = optional(any)<br/>  }))</pre> | `{}` | no |
| <a name="input_cloudfront_functions"></a> [cloudfront\_functions](#input\_cloudfront\_functions) | Map of CloudFront Functions to create (keyed by function name) | <pre>map(object({<br/>    name    = string<br/>    runtime = optional(string, "cloudfront-js-1.0")<br/>    comment = optional(string)<br/>    code    = string<br/>    publish = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (affects nearly all resources) | `bool` | `true` | no |
| <a name="input_create_log_bucket"></a> [create\_log\_bucket](#input\_create\_log\_bucket) | Create S3 bucket for CloudFront logs (only used if enable\_logging=true and log\_bucket\_arn is null) | `bool` | `false` | no |
| <a name="input_distributions"></a> [distributions](#input\_distributions) | Map of CloudFront distributions to create | <pre>map(object({<br/>    origins = any<br/><br/>    default_cache_behavior = object({<br/>      target_origin_id = string<br/>      allowed_methods  = list(string)<br/>      cached_methods   = list(string)<br/>      viewer_protocol_policy = string<br/>      ttl = object({<br/>        min_ttl     = number<br/>        default_ttl = number<br/>        max_ttl     = number<br/>      })<br/>      compress                   = optional(bool, false)<br/>      cache_policy_id            = optional(string)<br/>      origin_request_policy_id   = optional(string)<br/>      response_headers_policy_id = optional(string)<br/>      use_forwarded_values       = optional(bool, false)<br/>      query_string               = optional(bool, false)<br/>      headers                    = optional(list(string), [])<br/>      cookies_forward            = optional(string, "none")<br/>      lambda_function_associations = optional(any, [])<br/>      function_associations      = optional(any, [])<br/>    })<br/><br/>    ordered_cache_behaviors = optional(list(object({<br/>      path_pattern     = string<br/>      target_origin_id = string<br/>      allowed_methods  = list(string)<br/>      cached_methods   = list(string)<br/>      viewer_protocol_policy = string<br/>      ttl = object({<br/>        min_ttl     = number<br/>        default_ttl = number<br/>        max_ttl     = number<br/>      })<br/>      compress                   = optional(bool, false)<br/>      cache_policy_id            = optional(string)<br/>      origin_request_policy_id   = optional(string)<br/>      response_headers_policy_id = optional(string)<br/>      use_forwarded_values       = optional(bool, false)<br/>      query_string               = optional(bool, false)<br/>      headers                    = optional(list(string), [])<br/>      cookies_forward            = optional(string, "none")<br/>      lambda_function_associations = optional(any, [])<br/>      function_associations      = optional(any, [])<br/>    })), [])<br/><br/>    custom_error_responses = optional(list(object({<br/>      error_caching_min_ttl = optional(number)<br/>      error_code            = number<br/>      response_code         = optional(number)<br/>      response_page_path    = optional(string)<br/>    })), [])<br/><br/>    default_root_object = optional(string, "index.html")<br/>    price_class         = optional(string, "PriceClass_All")<br/>    enabled             = optional(bool, true)<br/>    comment             = optional(string)<br/>    web_acl_id          = optional(string, null)<br/>    aliases             = optional(list(string), [])<br/>    viewer_certificate  = optional(any, null)<br/>    geo_restriction     = optional(any, {})<br/>    invalidation        = optional(any, null)<br/>  }))</pre> | n/a | yes |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable CloudFront access logging to S3 | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sbx) | `string` | n/a | yes |
| <a name="input_log_bucket_arn"></a> [log\_bucket\_arn](#input\_log\_bucket\_arn) | ARN of existing S3 bucket for CloudFront logs. If provided, this takes precedence over create\_log\_bucket. | `string` | `null` | no |
| <a name="input_log_prefix"></a> [log\_prefix](#input\_log\_prefix) | Prefix for CloudFront log files in S3 bucket | `string` | `"cloudfront/"` | no |
| <a name="input_origin_request_policies"></a> [origin\_request\_policies](#input\_origin\_request\_policies) | Map of origin request policies to create (keyed by policy name) | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    headers_config = optional(object({<br/>      header_behavior = string<br/>      headers         = optional(list(string), [])<br/>    }))<br/>    cookies_config = optional(object({<br/>      cookie_behavior = string<br/>      cookies         = optional(list(string), [])<br/>    }))<br/>    query_strings_config = optional(object({<br/>      query_string_behavior = string<br/>      query_strings         = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_response_headers_policies"></a> [response\_headers\_policies](#input\_response\_headers\_policies) | Map of response headers policies to create (keyed by policy name) | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    cors_config = optional(object({<br/>      access_control_allow_credentials = bool<br/>      access_control_allow_headers     = list(string)<br/>      access_control_allow_methods     = list(string)<br/>      access_control_allow_origins     = list(string)<br/>      access_control_expose_headers    = optional(list(string), [])<br/>      access_control_max_age_sec       = optional(number)<br/>    }))<br/>    security_headers_config = optional(any)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cache_policies"></a> [cache\_policies](#output\_cache\_policies) | Map of Cache Policies |
| <a name="output_cache_policy_ids"></a> [cache\_policy\_ids](#output\_cache\_policy\_ids) | Map of Cache Policy IDs |
| <a name="output_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#output\_cloudfront\_function\_arns) | Map of CloudFront Function ARNs |
| <a name="output_cloudfront_function_ids"></a> [cloudfront\_function\_ids](#output\_cloudfront\_function\_ids) | Map of CloudFront Function IDs |
| <a name="output_cloudfront_functions"></a> [cloudfront\_functions](#output\_cloudfront\_functions) | Map of CloudFront Functions |
| <a name="output_configuration_summary"></a> [configuration\_summary](#output\_configuration\_summary) | Summary of CloudFront configuration |
| <a name="output_distribution_arns"></a> [distribution\_arns](#output\_distribution\_arns) | Map of CloudFront distribution ARNs |
| <a name="output_distribution_domain_names"></a> [distribution\_domain\_names](#output\_distribution\_domain\_names) | Map of CloudFront distribution domain names |
| <a name="output_distribution_hosted_zone_ids"></a> [distribution\_hosted\_zone\_ids](#output\_distribution\_hosted\_zone\_ids) | Map of CloudFront distribution hosted zone IDs |
| <a name="output_distribution_ids"></a> [distribution\_ids](#output\_distribution\_ids) | Map of CloudFront distribution IDs |
| <a name="output_distribution_statuses"></a> [distribution\_statuses](#output\_distribution\_statuses) | Map of CloudFront distribution statuses |
| <a name="output_distributions"></a> [distributions](#output\_distributions) | Map of CloudFront distributions |
| <a name="output_log_bucket"></a> [log\_bucket](#output\_log\_bucket) | S3 bucket for CloudFront access logs |
| <a name="output_log_bucket_arn"></a> [log\_bucket\_arn](#output\_log\_bucket\_arn) | ARN of S3 bucket for CloudFront access logs |
| <a name="output_log_bucket_domain_name"></a> [log\_bucket\_domain\_name](#output\_log\_bucket\_domain\_name) | Domain name of S3 bucket for CloudFront access logs |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | Name of S3 bucket for CloudFront access logs |
| <a name="output_origin_access_identities"></a> [origin\_access\_identities](#output\_origin\_access\_identities) | Map of Origin Access Identity resources |
| <a name="output_origin_access_identity_iam_arns"></a> [origin\_access\_identity\_iam\_arns](#output\_origin\_access\_identity\_iam\_arns) | Map of Origin Access Identity IAM ARNs |
| <a name="output_origin_access_identity_ids"></a> [origin\_access\_identity\_ids](#output\_origin\_access\_identity\_ids) | Map of Origin Access Identity IDs |
| <a name="output_origin_request_policies"></a> [origin\_request\_policies](#output\_origin\_request\_policies) | Map of Origin Request Policies |
| <a name="output_origin_request_policy_ids"></a> [origin\_request\_policy\_ids](#output\_origin\_request\_policy\_ids) | Map of Origin Request Policy IDs |
| <a name="output_response_headers_policies"></a> [response\_headers\_policies](#output\_response\_headers\_policies) | Map of Response Headers Policies |
| <a name="output_response_headers_policy_arns"></a> [response\_headers\_policy\_arns](#output\_response\_headers\_policy\_arns) | Map of Response Headers Policy ARNs |
| <a name="output_response_headers_policy_ids"></a> [response\_headers\_policy\_ids](#output\_response\_headers\_policy\_ids) | Map of Response Headers Policy IDs |
<!-- END_TF_DOCS -->