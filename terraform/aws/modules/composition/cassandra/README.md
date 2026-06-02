<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_seed_discovery_api"></a> [seed\_discovery\_api](#module\_seed\_discovery\_api) | ../../base/api-gateway | n/a |
| <a name="module_seed_discovery_lambda"></a> [seed\_discovery\_lambda](#module\_seed\_discovery\_lambda) | ../../base/lambda | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_instance_profile.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cassandra_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_network_interface.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.cassandra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cassandra_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cassandra_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cassandra_vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_cassandra_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.cassandra_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [tls_private_key.cassandra](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_subnet_ids"></a> [additional\_subnet\_ids](#input\_additional\_subnet\_ids) | Additional subnet IDs for multi-AZ deployment (optional) | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for Cassandra instances (ARM-based AMI recommended for m7g instances) | `string` | n/a | yes |
| <a name="input_api_gateway_vpce_id"></a> [api\_gateway\_vpce\_id](#input\_api\_gateway\_vpce\_id) | VPC Endpoint ID for the API Gateway (execute-api). Required for PRIVATE API Gateway endpoint type. | `string` | `null` | no |
| <a name="input_cassandra_ports"></a> [cassandra\_ports](#input\_cassandra\_ports) | Cassandra service ports to open within the cluster | <pre>object({<br/>    storage     = optional(number, 7000) # Inter-node communication<br/>    storage_ssl = optional(number, 7001) # SSL inter-node communication<br/>    jmx         = optional(number, 7199) # JMX monitoring<br/>    native      = optional(number, 9042) # CQL native transport<br/>    thrift      = optional(number, 9160) # Thrift client (legacy)<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cassandra cluster name | `string` | `"cassandra-hyperswitch"` | no |
| <a name="input_cluster_tag_name"></a> [cluster\_tag\_name](#input\_cluster\_tag\_name) | Tag name used to identify Cassandra cluster instances for seed discovery | `string` | `"cluster"` | no |
| <a name="input_cluster_tag_value"></a> [cluster\_tag\_value](#input\_cluster\_tag\_value) | Tag value used to identify Cassandra cluster instances for seed discovery | `string` | `"cassandra-cluster"` | no |
| <a name="input_create_key_pair"></a> [create\_key\_pair](#input\_create\_key\_pair) | Whether to create a new SSH key pair | `bool` | `false` | no |
| <a name="input_create_seed_discovery"></a> [create\_seed\_discovery](#input\_create\_seed\_discovery) | Whether to create the seed discovery Lambda and API Gateway. Defaults to true if seeds\_url is not provided. | `bool` | `true` | no |
| <a name="input_default_config_path"></a> [default\_config\_path](#input\_default\_config\_path) | Default Cassandra configuration path/profile | `string` | `"ReadWriteHeavy"` | no |
| <a name="input_ebs_device_name"></a> [ebs\_device\_name](#input\_ebs\_device\_name) | Device name for the additional EBS volume | `string` | `"/dev/sdh"` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | Size of the additional EBS volume in GB for Cassandra data | `number` | `100` | no |
| <a name="input_ebs_volume_type"></a> [ebs\_volume\_type](#input\_ebs\_volume\_type) | Type of the additional EBS volume | `string` | `"gp3"` | no |
| <a name="input_eni_tag_name"></a> [eni\_tag\_name](#input\_eni\_tag\_name) | Tag name used to identify Cassandra ENIs | `string` | `"cluster"` | no |
| <a name="input_eni_tag_value"></a> [eni\_tag\_value](#input\_eni\_tag\_value) | Tag value used to identify Cassandra ENIs | `string` | `"cassandra"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod) | `string` | n/a | yes |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | Cassandra idle timeout | `string` | `"3600000ms"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for Cassandra nodes | `string` | `"m7g.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name. Required if create\_key\_pair is false. | `string` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for CloudWatch log group encryption | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_metadata_http_tokens"></a> [metadata\_http\_tokens](#input\_metadata\_http\_tokens) | IMDSv2 setting for EC2 instances - 'required' for IMDSv2 only, 'optional' for IMDSv1 and IMDSv2 | `string` | `"required"` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of Cassandra nodes to create | `number` | `3` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | Public key material for creating new SSH key pair. If not provided when create\_key\_pair is true, a key pair will be auto-generated and stored in SSM | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources | `string` | `null` | no |
| <a name="input_replication_factor"></a> [replication\_factor](#input\_replication\_factor) | Cassandra replication factor | `number` | `3` | no |
| <a name="input_seed_discovery_lambda_source_path"></a> [seed\_discovery\_lambda\_source\_path](#input\_seed\_discovery\_lambda\_source\_path) | Path to the seed discovery Lambda function source file. Required when create\_seed\_discovery is true and seeds\_url is not provided. | `string` | `null` | no |
| <a name="input_seeds_url"></a> [seeds\_url](#input\_seeds\_url) | URL of the seed discovery API (Lambda/API Gateway endpoint) that returns seed node IPs. If not provided, a Lambda and API Gateway will be created automatically. | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for Cassandra instances and ENIs | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#input\_vpc\_endpoint\_security\_group\_id) | Security group ID for VPC endpoints. Required to allow HTTPS access from Cassandra to VPC endpoints (EC2 API). | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cassandra_security_group_arn"></a> [cassandra\_security\_group\_arn](#output\_cassandra\_security\_group\_arn) | Security group ARN of the Cassandra cluster |
| <a name="output_cassandra_security_group_id"></a> [cassandra\_security\_group\_id](#output\_cassandra\_security\_group\_id) | Security group ID of the Cassandra cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cassandra cluster name |
| <a name="output_eni_ids"></a> [eni\_ids](#output\_eni\_ids) | List of ENI IDs attached to Cassandra instances (stable IPs) |
| <a name="output_eni_private_ips"></a> [eni\_private\_ips](#output\_eni\_private\_ips) | List of private IPs of the ENIs (stable across instance replacements) |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role attached to Cassandra instances |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role attached to Cassandra instances |
| <a name="output_instance_arns"></a> [instance\_arns](#output\_instance\_arns) | List of ARNs of the Cassandra instances |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | List of IDs of the Cassandra instances |
| <a name="output_instance_private_ips"></a> [instance\_private\_ips](#output\_instance\_private\_ips) | List of private IP addresses of the Cassandra instances |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN of the IAM instance profile for Cassandra instances |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the IAM instance profile for Cassandra instances |
| <a name="output_key_name"></a> [key\_name](#output\_key\_name) | SSH key pair name used for Cassandra instances |
| <a name="output_native_port"></a> [native\_port](#output\_native\_port) | Cassandra CQL native transport port |
| <a name="output_seed_discovery_api_id"></a> [seed\_discovery\_api\_id](#output\_seed\_discovery\_api\_id) | ID of the seed discovery API Gateway |
| <a name="output_seed_discovery_api_invoke_url"></a> [seed\_discovery\_api\_invoke\_url](#output\_seed\_discovery\_api\_invoke\_url) | Invoke URL of the seed discovery API Gateway |
| <a name="output_seed_discovery_lambda_function_arn"></a> [seed\_discovery\_lambda\_function\_arn](#output\_seed\_discovery\_lambda\_function\_arn) | ARN of the seed discovery Lambda function |
| <a name="output_seed_discovery_lambda_function_name"></a> [seed\_discovery\_lambda\_function\_name](#output\_seed\_discovery\_lambda\_function\_name) | Name of the seed discovery Lambda function |
| <a name="output_seeds_url"></a> [seeds\_url](#output\_seeds\_url) | URL of the seed discovery API used by this cluster |
| <a name="output_ssh_private_key_ssm_parameter"></a> [ssh\_private\_key\_ssm\_parameter](#output\_ssh\_private\_key\_ssm\_parameter) | SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated) |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID where the Cassandra instances are deployed |
<!-- END_TF_DOCS -->