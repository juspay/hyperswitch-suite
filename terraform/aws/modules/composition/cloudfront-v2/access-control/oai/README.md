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
| [aws_cloudfront_origin_access_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_origin_access_identities"></a> [origin\_access\_identities](#input\_origin\_access\_identities) | Map of OAI configurations | <pre>map(object({<br/>    comment = optional(string, "")<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oai_canonical_user_ids"></a> [oai\_canonical\_user\_ids](#output\_oai\_canonical\_user\_ids) | Map of OAI names to canonical user IDs |
| <a name="output_oai_iam_arns"></a> [oai\_iam\_arns](#output\_oai\_iam\_arns) | Map of OAI names to IAM ARNs |
| <a name="output_oai_ids"></a> [oai\_ids](#output\_oai\_ids) | Map of OAI names to IDs |
<!-- END_TF_DOCS -->