<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_cloudfront_origin_request_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_request_policy) | resource |
| [aws_cloudfront_response_headers_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_policies"></a> [cache\_policies](#input\_cache\_policies) | Map of cache policies to create (keyed by policy name for stable resource tracking) | <pre>map(object({<br/>    name        = string<br/>    comment     = optional(string)<br/>    default_ttl = optional(number)<br/>    max_ttl     = optional(number)<br/>    min_ttl     = optional(number)<br/>    parameters_in_cache_key_and_forwarded_to_origin = optional(object({<br/>      enable_accept_encoding_brotli = optional(bool, false)<br/>      enable_accept_encoding_gzip  = optional(bool, true)<br/>      headers_config = optional(object({<br/>        header_behavior = string<br/>        headers         = optional(list(string), [])<br/>      }))<br/>      cookies_config = optional(object({<br/>        cookie_behavior = string<br/>        cookies         = optional(list(string), [])<br/>      }))<br/>      query_strings_config = optional(object({<br/>        query_string_behavior = string<br/>        query_strings         = optional(list(string), [])<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cloudfront_functions"></a> [cloudfront\_functions](#input\_cloudfront\_functions) | Map of CloudFront Functions to create (keyed by function name for stable resource tracking) | <pre>map(object({<br/>    name    = string<br/>    runtime = optional(string, "cloudfront-js-1.0")<br/>    comment = optional(string)<br/>    code    = string<br/>    publish = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply | `map(string)` | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_origin_request_policies"></a> [origin\_request\_policies](#input\_origin\_request\_policies) | Map of origin request policies to create (keyed by policy name for stable resource tracking) | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    headers_config = optional(object({<br/>      header_behavior = string<br/>      headers         = optional(list(string), [])<br/>    }))<br/>    cookies_config = optional(object({<br/>      cookie_behavior = string<br/>      cookies         = optional(list(string), [])<br/>    }))<br/>    query_strings_config = optional(object({<br/>      query_string_behavior = string<br/>      query_strings         = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name | `string` | n/a | yes |
| <a name="input_response_headers_policies"></a> [response\_headers\_policies](#input\_response\_headers\_policies) | Map of response headers policies to create (keyed by policy name for stable resource tracking) | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    cors_config = optional(object({<br/>      access_control_allow_credentials = bool<br/>      access_control_allow_headers     = list(string)<br/>      access_control_allow_methods     = list(string)<br/>      access_control_allow_origins     = list(string)<br/>      access_control_expose_headers    = optional(list(string), [])<br/>      access_control_max_age_sec       = optional(number)<br/>    }))<br/>    security_headers_config = optional(any) # Can be extended for security headers<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cache_policies"></a> [cache\_policies](#output\_cache\_policies) | Map of Cache Policies |
| <a name="output_cache_policy_ids"></a> [cache\_policy\_ids](#output\_cache\_policy\_ids) | Map of Cache Policy IDs |
| <a name="output_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#output\_cloudfront\_function\_arns) | Map of CloudFront Function ARNs |
| <a name="output_cloudfront_function_ids"></a> [cloudfront\_function\_ids](#output\_cloudfront\_function\_ids) | Map of CloudFront Function IDs |
| <a name="output_cloudfront_function_names"></a> [cloudfront\_function\_names](#output\_cloudfront\_function\_names) | List of CloudFront Function names |
| <a name="output_cloudfront_functions"></a> [cloudfront\_functions](#output\_cloudfront\_functions) | Map of CloudFront Functions |
| <a name="output_origin_request_policies"></a> [origin\_request\_policies](#output\_origin\_request\_policies) | Map of Origin Request Policies |
| <a name="output_origin_request_policy_ids"></a> [origin\_request\_policy\_ids](#output\_origin\_request\_policy\_ids) | Map of Origin Request Policy IDs |
| <a name="output_response_headers_policies"></a> [response\_headers\_policies](#output\_response\_headers\_policies) | Map of Response Headers Policies |
| <a name="output_response_headers_policy_arns"></a> [response\_headers\_policy\_arns](#output\_response\_headers\_policy\_arns) | Map of Response Headers Policy ARNs |
| <a name="output_response_headers_policy_ids"></a> [response\_headers\_policy\_ids](#output\_response\_headers\_policy\_ids) | Map of Response Headers Policy IDs |
<!-- END_TF_DOCS -->