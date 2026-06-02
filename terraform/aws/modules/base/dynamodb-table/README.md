<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | List of attribute definitions | <pre>list(object({<br/>    name = string<br/>    type = string  # S (string), N (number), or B (binary)<br/>  }))</pre> | n/a | yes |
| <a name="input_billing_mode"></a> [billing\_mode](#input\_billing\_mode) | Billing mode for the table (PROVISIONED or PAY\_PER\_REQUEST) | `string` | `"PAY_PER_REQUEST"` | no |
| <a name="input_enable_encryption"></a> [enable\_encryption](#input\_enable\_encryption) | Enable server-side encryption | `bool` | `true` | no |
| <a name="input_enable_point_in_time_recovery"></a> [enable\_point\_in\_time\_recovery](#input\_enable\_point\_in\_time\_recovery) | Enable point-in-time recovery for the table | `bool` | `false` | no |
| <a name="input_global_secondary_indexes"></a> [global\_secondary\_indexes](#input\_global\_secondary\_indexes) | List of global secondary indexes | <pre>list(object({<br/>    name            = string<br/>    hash_key        = string<br/>    range_key       = optional(string, null)<br/>    projection_type = string  # ALL, KEYS_ONLY, or INCLUDE<br/>    read_capacity   = optional(number, 5)<br/>    write_capacity  = optional(number, 5)<br/>  }))</pre> | `[]` | no |
| <a name="input_hash_key"></a> [hash\_key](#input\_hash\_key) | Attribute to use as the hash (partition) key | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key for encryption (null uses AWS managed key) | `string` | `null` | no |
| <a name="input_local_secondary_indexes"></a> [local\_secondary\_indexes](#input\_local\_secondary\_indexes) | List of local secondary indexes | <pre>list(object({<br/>    name            = string<br/>    range_key       = string<br/>    projection_type = string  # ALL, KEYS_ONLY, or INCLUDE<br/>  }))</pre> | `[]` | no |
| <a name="input_range_key"></a> [range\_key](#input\_range\_key) | Attribute to use as the range (sort) key | `string` | `null` | no |
| <a name="input_read_capacity"></a> [read\_capacity](#input\_read\_capacity) | Read capacity units (only used with PROVISIONED billing mode) | `number` | `5` | no |
| <a name="input_table_name"></a> [table\_name](#input\_table\_name) | Name of the DynamoDB table | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the table | `map(string)` | `{}` | no |
| <a name="input_ttl_attribute_name"></a> [ttl\_attribute\_name](#input\_ttl\_attribute\_name) | Name of the attribute to use for TTL | `string` | `null` | no |
| <a name="input_ttl_enabled"></a> [ttl\_enabled](#input\_ttl\_enabled) | Enable TTL for the table | `bool` | `false` | no |
| <a name="input_write_capacity"></a> [write\_capacity](#input\_write\_capacity) | Write capacity units (only used with PROVISIONED billing mode) | `number` | `5` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_table_arn"></a> [table\_arn](#output\_table\_arn) | The ARN of the table |
| <a name="output_table_id"></a> [table\_id](#output\_table\_id) | The ID (name) of the table |
| <a name="output_table_name"></a> [table\_name](#output\_table\_name) | The name of the table |
| <a name="output_table_stream_arn"></a> [table\_stream\_arn](#output\_table\_stream\_arn) | The ARN of the table stream (if enabled) |
| <a name="output_table_stream_label"></a> [table\_stream\_label](#output\_table\_stream\_label) | The stream label of the table (if enabled) |
<!-- END_TF_DOCS -->