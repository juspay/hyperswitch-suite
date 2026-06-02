<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.13.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_time"></a> [time](#provider\_time) | >= 0.13.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.kafka](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.kafka](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.kafka_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.kafka_sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.kafka](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_network_interface.broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.broker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.broker_from_controller_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.broker_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.broker_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.broker_to_controller_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.broker_vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.controller_from_broker_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.controller_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.controller_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.controller_to_broker_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.controller_vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_broker_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_controller_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.kafka_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [time_sleep.wait_for_controller](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.kafka](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_broker_ami_id"></a> [broker\_ami\_id](#input\_broker\_ami\_id) | AMI ID for Kafka broker instances | `string` | n/a | yes |
| <a name="input_broker_count"></a> [broker\_count](#input\_broker\_count) | Number of Kafka broker nodes to create | `number` | `3` | no |
| <a name="input_broker_data_device_name"></a> [broker\_data\_device\_name](#input\_broker\_data\_device\_name) | Device name for the broker data EBS volume | `string` | `"/dev/sdb"` | no |
| <a name="input_broker_data_volume_size"></a> [broker\_data\_volume\_size](#input\_broker\_data\_volume\_size) | Size of the additional EBS volume in GB for Kafka broker data | `number` | `10` | no |
| <a name="input_broker_data_volume_type"></a> [broker\_data\_volume\_type](#input\_broker\_data\_volume\_type) | Type of the additional EBS volume for broker data | `string` | `"gp3"` | no |
| <a name="input_broker_instance_type"></a> [broker\_instance\_type](#input\_broker\_instance\_type) | EC2 instance type for Kafka brokers | `string` | `"t4g.medium"` | no |
| <a name="input_broker_root_volume_size"></a> [broker\_root\_volume\_size](#input\_broker\_root\_volume\_size) | Size of the broker root EBS volume in GB | `number` | `30` | no |
| <a name="input_broker_root_volume_type"></a> [broker\_root\_volume\_type](#input\_broker\_root\_volume\_type) | Type of the broker root EBS volume | `string` | `"gp3"` | no |
| <a name="input_broker_subnet_id"></a> [broker\_subnet\_id](#input\_broker\_subnet\_id) | Subnet ID for Kafka broker instances and ENIs | `string` | n/a | yes |
| <a name="input_broker_user_data_override"></a> [broker\_user\_data\_override](#input\_broker\_user\_data\_override) | Custom user data for broker instances. If provided, this will be used instead of the default JSON user data. | `string` | `null` | no |
| <a name="input_controller_ami_id"></a> [controller\_ami\_id](#input\_controller\_ami\_id) | AMI ID for Kafka controller instances | `string` | n/a | yes |
| <a name="input_controller_instance_type"></a> [controller\_instance\_type](#input\_controller\_instance\_type) | EC2 instance type for Kafka controllers | `string` | `"c7g.medium"` | no |
| <a name="input_controller_metadata_device_name"></a> [controller\_metadata\_device\_name](#input\_controller\_metadata\_device\_name) | Device name for the controller metadata EBS volume | `string` | `"/dev/sdb"` | no |
| <a name="input_controller_metadata_volume_size"></a> [controller\_metadata\_volume\_size](#input\_controller\_metadata\_volume\_size) | Size of the additional EBS volume in GB for Kafka controller metadata | `number` | `10` | no |
| <a name="input_controller_metadata_volume_type"></a> [controller\_metadata\_volume\_type](#input\_controller\_metadata\_volume\_type) | Type of the additional EBS volume for controller metadata | `string` | `"gp3"` | no |
| <a name="input_controller_root_volume_size"></a> [controller\_root\_volume\_size](#input\_controller\_root\_volume\_size) | Size of the controller root EBS volume in GB | `number` | `30` | no |
| <a name="input_controller_root_volume_type"></a> [controller\_root\_volume\_type](#input\_controller\_root\_volume\_type) | Type of the controller root EBS volume | `string` | `"gp3"` | no |
| <a name="input_controller_subnet_id"></a> [controller\_subnet\_id](#input\_controller\_subnet\_id) | Subnet ID for Kafka controller instances and ENIs | `string` | n/a | yes |
| <a name="input_controller_user_data_override"></a> [controller\_user\_data\_override](#input\_controller\_user\_data\_override) | Custom user data for controller instance. If provided, this will be used instead of the default JSON user data. | `string` | `null` | no |
| <a name="input_create_key_pair"></a> [create\_key\_pair](#input\_create\_key\_pair) | Whether to create a new SSH key pair | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod/sandbox) | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name. Required if create\_key\_pair is false. | `string` | `null` | no |
| <a name="input_metadata_http_tokens"></a> [metadata\_http\_tokens](#input\_metadata\_http\_tokens) | IMDSv2 setting for EC2 instances - 'required' for IMDSv2 only, 'optional' for IMDSv1 and IMDSv2 | `string` | `"required"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | Public key material for creating new SSH key pair. If not provided when create\_key\_pair is true, a key pair will be auto-generated and stored in SSM | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#input\_vpc\_endpoint\_security\_group\_id) | Security group ID of VPC endpoints for HTTPS egress from Kafka instances | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_broker_eni_ids"></a> [broker\_eni\_ids](#output\_broker\_eni\_ids) | List of ENI IDs attached to Kafka broker instances |
| <a name="output_broker_eni_private_ips"></a> [broker\_eni\_private\_ips](#output\_broker\_eni\_private\_ips) | List of private IPs of the broker ENIs |
| <a name="output_broker_instance_ids"></a> [broker\_instance\_ids](#output\_broker\_instance\_ids) | List of IDs of the Kafka broker instances |
| <a name="output_broker_instance_private_ips"></a> [broker\_instance\_private\_ips](#output\_broker\_instance\_private\_ips) | List of private IP addresses of the Kafka broker instances |
| <a name="output_broker_ips_string_list"></a> [broker\_ips\_string\_list](#output\_broker\_ips\_string\_list) | Comma-separated list of private IPs of the broker ENIs |
| <a name="output_broker_security_group_id"></a> [broker\_security\_group\_id](#output\_broker\_security\_group\_id) | Security group ID of the Kafka broker nodes |
| <a name="output_controller_eni_ids"></a> [controller\_eni\_ids](#output\_controller\_eni\_ids) | List of ENI IDs attached to Kafka controller instances |
| <a name="output_controller_eni_private_ips"></a> [controller\_eni\_private\_ips](#output\_controller\_eni\_private\_ips) | List of private IPs of the controller ENIs |
| <a name="output_controller_instance_ids"></a> [controller\_instance\_ids](#output\_controller\_instance\_ids) | List of IDs of the Kafka controller instances |
| <a name="output_controller_instance_private_ips"></a> [controller\_instance\_private\_ips](#output\_controller\_instance\_private\_ips) | List of private IP addresses of the Kafka controller instances |
| <a name="output_controller_security_group_id"></a> [controller\_security\_group\_id](#output\_controller\_security\_group\_id) | Security group ID of the Kafka controller nodes |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role attached to Kafka instances |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role attached to Kafka instances |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the IAM instance profile for Kafka instances |
| <a name="output_key_name"></a> [key\_name](#output\_key\_name) | SSH key pair name used for Kafka instances |
| <a name="output_ssh_private_key_ssm_parameter"></a> [ssh\_private\_key\_ssm\_parameter](#output\_ssh\_private\_key\_ssm\_parameter) | SSM Parameter Store path for the auto-generated SSH private key (null if not auto-generated) |
<!-- END_TF_DOCS -->