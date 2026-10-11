<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_origin_request_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_request_policy) | resource |
| [aws_cloudfront_response_headers_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy) | resource |
| [aws_cloudfront_cache_policy.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_cloudfront_response_headers_policy.managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created | `bool` | `true` | no |
| <a name="input_custom_cache_policies"></a> [custom\_cache\_policies](#input\_custom\_cache\_policies) | Map of custom cache policies to create | <pre>map(object({<br/>    name        = string<br/>    comment     = optional(string)<br/>    default_ttl = optional(number)<br/>    max_ttl     = optional(number)<br/>    min_ttl     = optional(number)<br/>    enable_accept_encoding_brotli = optional(bool, false)<br/>    enable_accept_encoding_gzip   = optional(bool, true)<br/>    headers_config_header_behavior = optional(string, "none")<br/>    headers_config_headers         = optional(list(string), [])<br/>    cookies_config_cookie_behavior = optional(string, "none")<br/>    cookies_config_cookies         = optional(list(string), [])<br/>    query_strings_config_query_string_behavior = optional(string, "none")<br/>    query_strings_config_query_strings         = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_origin_request_policies"></a> [custom\_origin\_request\_policies](#input\_custom\_origin\_request\_policies) | Map of custom origin request policies to create | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    headers_config_header_behavior = optional(string, "none")<br/>    headers_config_headers         = optional(list(string), [])<br/>    cookies_config_cookie_behavior = optional(string, "none")<br/>    cookies_config_cookies         = optional(list(string), [])<br/>    query_strings_config_query_string_behavior = optional(string, "none")<br/>    query_strings_config_query_strings         = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_response_headers_policies"></a> [custom\_response\_headers\_policies](#input\_custom\_response\_headers\_policies) | Map of custom response headers policies to create | <pre>map(object({<br/>    name    = string<br/>    comment = optional(string)<br/>    cors_config = optional(object({<br/>      access_control_allow_credentials = bool<br/>      access_control_allow_headers     = list(string)<br/>      access_control_allow_methods     = list(string)<br/>      access_control_allow_origins     = list(string)<br/>      access_control_expose_headers    = optional(list(string), [])<br/>      access_control_max_age_sec       = optional(number)<br/>      origin_override                  = optional(bool, true)<br/>    }))<br/>    security_headers_config = optional(any)<br/>    remove_headers_config = optional(object({<br/>      items = list(string)<br/>    }))<br/>    custom_headers_config = optional(object({<br/>      items = list(object({<br/>        header   = string<br/>        value    = string<br/>        override = bool<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | n/a | yes |
| <a name="input_managed_cache_policies"></a> [managed\_cache\_policies](#input\_managed\_cache\_policies) | List of AWS managed cache policy names to look up | `list(string)` | `[]` | no |
| <a name="input_managed_origin_request_policies"></a> [managed\_origin\_request\_policies](#input\_managed\_origin\_request\_policies) | List of AWS managed origin request policy names to look up | `list(string)` | `[]` | no |
| <a name="input_managed_response_headers_policies"></a> [managed\_response\_headers\_policies](#input\_managed\_response\_headers\_policies) | List of AWS managed response headers policy names to look up | `list(string)` | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name | `string` | `"hyperswitch"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_all_cache_policy_ids"></a> [all\_cache\_policy\_ids](#output\_all\_cache\_policy\_ids) | Combined map of managed and custom cache policy IDs |
| <a name="output_all_origin_request_policy_ids"></a> [all\_origin\_request\_policy\_ids](#output\_all\_origin\_request\_policy\_ids) | Combined map of managed and custom origin request policy IDs |
| <a name="output_all_response_headers_policy_ids"></a> [all\_response\_headers\_policy\_ids](#output\_all\_response\_headers\_policy\_ids) | Combined map of managed and custom response headers policy IDs |
| <a name="output_custom_cache_policy_ids"></a> [custom\_cache\_policy\_ids](#output\_custom\_cache\_policy\_ids) | Map of custom cache policy IDs by key |
| <a name="output_custom_origin_request_policy_ids"></a> [custom\_origin\_request\_policy\_ids](#output\_custom\_origin\_request\_policy\_ids) | Map of custom origin request policy IDs by key |
| <a name="output_custom_response_headers_policy_ids"></a> [custom\_response\_headers\_policy\_ids](#output\_custom\_response\_headers\_policy\_ids) | Map of custom response headers policy IDs by key |
| <a name="output_managed_cache_policy_ids"></a> [managed\_cache\_policy\_ids](#output\_managed\_cache\_policy\_ids) | Map of managed cache policy IDs by name |
| <a name="output_managed_origin_request_policy_ids"></a> [managed\_origin\_request\_policy\_ids](#output\_managed\_origin\_request\_policy\_ids) | Map of managed origin request policy IDs by name |
| <a name="output_managed_response_headers_policy_ids"></a> [managed\_response\_headers\_policy\_ids](#output\_managed\_response\_headers\_policy\_ids) | Map of managed response headers policy IDs by name |
<!-- END_TF_DOCS -->