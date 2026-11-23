<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_distribution"></a> [distribution](#module\_distribution) | terraform-aws-modules/cloudfront/aws | ~> 6.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aliases"></a> [aliases](#input\_aliases) | n/a | `list(string)` | `[]` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | n/a | `string` | `""` | no |
| <a name="input_continuous_deployment_policy_id"></a> [continuous\_deployment\_policy\_id](#input\_continuous\_deployment\_policy\_id) | n/a | `string` | `null` | no |
| <a name="input_create"></a> [create](#input\_create) | n/a | `bool` | `true` | no |
| <a name="input_custom_error_responses"></a> [custom\_error\_responses](#input\_custom\_error\_responses) | n/a | `list(any)` | `[]` | no |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | n/a | `any` | `{}` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | n/a | `string` | `""` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_geo_restriction"></a> [geo\_restriction](#input\_geo\_restriction) | n/a | `any` | <pre>{<br/>  "locations": [],<br/>  "restriction_type": "none"<br/>}</pre> | no |
| <a name="input_http_version"></a> [http\_version](#input\_http\_version) | n/a | `string` | `"http2"` | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_logging_config"></a> [logging\_config](#input\_logging\_config) | n/a | `any` | `{}` | no |
| <a name="input_ordered_cache_behaviors"></a> [ordered\_cache\_behaviors](#input\_ordered\_cache\_behaviors) | n/a | `list(any)` | `[]` | no |
| <a name="input_origin_access_control"></a> [origin\_access\_control](#input\_origin\_access\_control) | n/a | `map(any)` | `{}` | no |
| <a name="input_origin_groups"></a> [origin\_groups](#input\_origin\_groups) | n/a | `any` | `{}` | no |
| <a name="input_origins"></a> [origins](#input\_origins) | n/a | `any` | `{}` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | n/a | `string` | `"PriceClass_All"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | n/a | `string` | `"hyperswitch"` | no |
| <a name="input_retain_on_delete"></a> [retain\_on\_delete](#input\_retain\_on\_delete) | n/a | `bool` | `false` | no |
| <a name="input_staging"></a> [staging](#input\_staging) | n/a | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_viewer_certificate"></a> [viewer\_certificate](#input\_viewer\_certificate) | n/a | `any` | `{}` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | n/a | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_distribution_arn"></a> [distribution\_arn](#output\_distribution\_arn) | The ARN for the CloudFront distribution |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | The identifier for the CloudFront distribution |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | The domain name corresponding to the CloudFront distribution |
| <a name="output_etag"></a> [etag](#output\_etag) | The current version of the distribution's information |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The CloudFront Route 53 zone ID |
| <a name="output_oac_objects"></a> [oac\_objects](#output\_oac\_objects) | Map of OAC name to full object (contains id, arn, etc) |
| <a name="output_status"></a> [status](#output\_status) | The current status of the distribution |
<!-- END_TF_DOCS -->