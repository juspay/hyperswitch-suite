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
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_origin_access_controls"></a> [origin\_access\_controls](#input\_origin\_access\_controls) | Map of OAC configurations | <pre>map(object({<br/>    name                              = string<br/>    description                       = optional(string, "")<br/>    origin_access_control_origin_type = optional(string, "s3")<br/>    signing_behavior                  = optional(string, "always")<br/>    signing_protocol                  = optional(string, "sigv4")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oac_arns"></a> [oac\_arns](#output\_oac\_arns) | Map of OAC names to ARNs |
| <a name="output_oac_ids"></a> [oac\_ids](#output\_oac\_ids) | Map of OAC names to IDs |
<!-- END_TF_DOCS -->