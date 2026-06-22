<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.20 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudfront_functions"></a> [cloudfront\_functions](#input\_cloudfront\_functions) | n/a | <pre>map(object({<br/>    name    = string<br/>    runtime = optional(string, "cloudfront-js-1.0")<br/>    comment = optional(string)<br/>    code    = string<br/>    publish = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_create"></a> [create](#input\_create) | n/a | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | n/a | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | n/a | `string` | `"hyperswitch"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_function_arns"></a> [cloudfront\_function\_arns](#output\_cloudfront\_function\_arns) | n/a |
| <a name="output_cloudfront_function_ids"></a> [cloudfront\_function\_ids](#output\_cloudfront\_function\_ids) | n/a |
| <a name="output_cloudfront_functions"></a> [cloudfront\_functions](#output\_cloudfront\_functions) | n/a |
<!-- END_TF_DOCS -->