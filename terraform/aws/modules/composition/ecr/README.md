<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.32.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.32.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_lifecycle_policy.lifecycle_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.repositories](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of ECR repository configurations | <pre>map(object({<br/>    name                 = string<br/>    image_tag_mutability = optional(string, "MUTABLE")<br/>    scan_on_push         = optional(bool, true)<br/>    encryption_type      = optional(string, "AES256")<br/>    kms_key              = optional(string)<br/>    force_delete         = optional(bool, false)<br/>    repository_policy    = optional(string)<br/>    lifecycle_policy     = optional(string)<br/>    image_tag_mutability_exclusion_filters = optional(list(object({<br/>      filter      = string<br/>      filter_type = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_lifecycle_policies"></a> [lifecycle\_policies](#output\_lifecycle\_policies) | Map of repository keys to their lifecycle policies |
| <a name="output_registry_ids"></a> [registry\_ids](#output\_registry\_ids) | Map of repository names to registry IDs |
| <a name="output_registry_url"></a> [registry\_url](#output\_registry\_url) | The registry URL for ECR (e.g., 701342709052.dkr.ecr.eu-central-1.amazonaws.com) |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | Map of repository names to ARNs |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of repository keys to repository names |
| <a name="output_repository_policies"></a> [repository\_policies](#output\_repository\_policies) | Map of repository keys to their policies |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Map of repository names to URLs |
<!-- END_TF_DOCS -->