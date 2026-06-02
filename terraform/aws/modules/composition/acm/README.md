<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_certificate"></a> [certificate](#module\_certificate) | terraform-aws-modules/acm/aws | 6.3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of ACM certificate configurations. Each key represents a certificate name.<br/>Example:<br/>certificates = {<br/>  "main" = {<br/>    domain\_name               = "example.com"<br/>    subject\_alternative\_names = ["*.example.com"]<br/>    zone\_id                   = "Z1234567890ABC"<br/>    validation\_method         = "DNS"<br/>    create\_route53\_records    = true<br/>    validate\_certificate      = true<br/>    wait\_for\_validation       = true<br/>  }<br/>  "api" = {<br/>    domain\_name = "api.example.com"<br/>    zone\_id     = "Z1234567890ABC"<br/>  }<br/>} | <pre>map(object({<br/>    domain_name                                 = string<br/>    subject_alternative_names                   = optional(list(string), [])<br/>    zone_id                                     = optional(string, null)<br/>    validation_method                           = optional(string, "DNS")<br/>    create_route53_records                      = optional(bool, false)<br/>    validate_certificate                        = optional(bool, false)<br/>    validation_record_fqdns                     = optional(list(string), [])<br/>    zones                                       = optional(map(string), {})<br/>    wait_for_validation                         = optional(bool, false)<br/>    validation_timeout                          = optional(string, null)<br/>    validation_allow_overwrite_records          = optional(bool, false)<br/>    certificate_transparency_logging_preference = optional(bool, true)<br/>    create_route53_records_only                 = optional(bool, false)<br/>    distinct_domain_names                       = optional(list(string), [])<br/>    acm_certificate_domain_validation_options   = optional(any, {})<br/>    key_algorithm                               = optional(string, null)<br/>    export                                      = optional(string, null)<br/>    private_authority_arn                       = optional(string, null)<br/>    tags                                        = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certificate_arns"></a> [certificate\_arns](#output\_certificate\_arns) | Map of certificate names to their ARNs |
| <a name="output_certificate_domain_validation_options"></a> [certificate\_domain\_validation\_options](#output\_certificate\_domain\_validation\_options) | Map of certificate names to their domain validation options |
| <a name="output_certificate_statuses"></a> [certificate\_statuses](#output\_certificate\_statuses) | Map of certificate names to their statuses |
| <a name="output_certificates"></a> [certificates](#output\_certificates) | Map of certificate names to their full output details |
| <a name="output_distinct_domain_names"></a> [distinct\_domain\_names](#output\_distinct\_domain\_names) | Map of certificate names to their distinct domain names |
| <a name="output_validation_route53_record_fqdns"></a> [validation\_route53\_record\_fqdns](#output\_validation\_route53\_record\_fqdns) | Map of certificate names to their Route53 validation record FQDNs |
<!-- END_TF_DOCS -->