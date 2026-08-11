<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_pubsub"></a> [pubsub](#module\_pubsub) | terraform-google-modules/pubsub/google | 8.8.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_persistence_regions"></a> [allowed\_persistence\_regions](#input\_allowed\_persistence\_regions) | List of regions messages may be persisted in. Null leaves the default (global) policy | `list(string)` | `null` | no |
| <a name="input_bigquery_subscriptions"></a> [bigquery\_subscriptions](#input\_bigquery\_subscriptions) | List of BigQuery subscriptions to create, in the shape expected by terraform-google-modules/pubsub | `any` | `[]` | no |
| <a name="input_cloud_storage_subscriptions"></a> [cloud\_storage\_subscriptions](#input\_cloud\_storage\_subscriptions) | List of Cloud Storage subscriptions to create, in the shape expected by terraform-google-modules/pubsub | `any` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to the topic and subscriptions | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the topic is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_pull_subscriptions"></a> [pull\_subscriptions](#input\_pull\_subscriptions) | List of pull subscriptions to create, in the shape expected by terraform-google-modules/pubsub | `any` | `[]` | no |
| <a name="input_push_subscriptions"></a> [push\_subscriptions](#input\_push\_subscriptions) | List of push subscriptions to create, in the shape expected by terraform-google-modules/pubsub | `any` | `[]` | no |
| <a name="input_topic"></a> [topic](#input\_topic) | Logical topic name, auto-prefixed with '<environment>-<project\_name>-' | `string` | n/a | yes |
| <a name="input_topic_kms_key_name"></a> [topic\_kms\_key\_name](#input\_topic\_kms\_key\_name) | Self-link of a KMS CryptoKey used to encrypt messages at rest. Null uses Google-managed encryption | `string` | `null` | no |
| <a name="input_topic_message_retention_duration"></a> [topic\_message\_retention\_duration](#input\_topic\_message\_retention\_duration) | How long to retain unacknowledged messages on the topic (e.g. '86400s'). Null uses the service default (7 days) | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_subscription_names"></a> [subscription\_names](#output\_subscription\_names) | Map of all created subscription names |
| <a name="output_subscription_paths"></a> [subscription\_paths](#output\_subscription\_paths) | Map of all created subscription fully qualified paths |
| <a name="output_topic"></a> [topic](#output\_topic) | Name of the created topic |
| <a name="output_topic_id"></a> [topic\_id](#output\_topic\_id) | Fully qualified ID of the topic |
<!-- END_TF_DOCS -->
