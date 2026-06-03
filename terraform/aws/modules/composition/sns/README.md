<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.32.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.32.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.topics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_data_protection_policy.data_protection_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_data_protection_policy) | resource |
| [aws_sns_topic_policy.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.subscriptions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | Map of SNS topic configurations | <pre>map(object({<br/>    name                        = string<br/>    display_name                = optional(string, "")<br/>    kms_master_key_id           = optional(string)<br/>    fifo_topic                  = optional(bool, false)<br/>    content_based_deduplication = optional(bool, false)<br/>    policy                      = optional(string)<br/>    data_protection_policy      = optional(string)<br/>    subscriptions = optional(map(object({<br/>      protocol                        = string<br/>      endpoint                        = string<br/>      filter_policy                   = optional(string)<br/>      raw_message_delivery            = optional(bool, false)<br/>      redrive_policy                  = optional(string)<br/>      delivery_policy                 = optional(string)<br/>      endpoint_auto_confirms          = optional(bool, false)<br/>      confirmation_timeout_in_minutes = optional(number, 1440)<br/>    })), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_region"></a> [region](#output\_region) | AWS region |
| <a name="output_subscription_arns"></a> [subscription\_arns](#output\_subscription\_arns) | Map of subscription keys to subscription ARNs |
| <a name="output_subscriptions"></a> [subscriptions](#output\_subscriptions) | Map of subscription keys to subscription details |
| <a name="output_topic_arns"></a> [topic\_arns](#output\_topic\_arns) | Map of topic keys to ARNs |
| <a name="output_topic_ids"></a> [topic\_ids](#output\_topic\_ids) | Map of topic keys to topic IDs |
| <a name="output_topic_names"></a> [topic\_names](#output\_topic\_names) | Map of topic keys to names |
| <a name="output_topic_policies"></a> [topic\_policies](#output\_topic\_policies) | Map of topic keys to their policies |
<!-- END_TF_DOCS -->