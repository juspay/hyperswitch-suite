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
| [aws_ebs_volume.keeper_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.keeper_data2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.server_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.server_data2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_iam_instance_profile.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.clickhouse_inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.clickhouse_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.keeper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_lb.clickhouse_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.clickhouse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_network_interface.keeper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_security_group.keeper](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.keeper_from_server_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.keeper_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.keeper_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.keeper_to_server_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.keeper_vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_from_keeper_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_self_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_self_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_to_keeper_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.server_vpc_endpoint_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_keeper_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpc_endpoint_server_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.clickhouse_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_volume_attachment.keeper_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.keeper_data2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.server_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.server_data2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [time_sleep.wait_for_keeper](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.clickhouse](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_alb_listeners"></a> [alb\_listeners](#input\_alb\_listeners) | ALB listener configurations for the Application Load Balancer | <pre>map(object({<br/>    port             = number<br/>    protocol         = string<br/>    target_group_arn = optional(string)<br/>    certificate_arn  = optional(string)<br/>  }))</pre> | <pre>{<br/>  "http": {<br/>    "port": 80,<br/>    "protocol": "HTTP"<br/>  }<br/>}</pre> | no |
| <a name="input_alb_subnet_ids"></a> [alb\_subnet\_ids](#input\_alb\_subnet\_ids) | List of subnet IDs for the Application Load Balancer. At least two subnets in two different Availability Zones are required. | `list(string)` | n/a | yes |
| <a name="input_clickhouse_port"></a> [clickhouse\_port](#input\_clickhouse\_port) | Port for Clickhouse HTTP interface | `number` | `8123` | no |
| <a name="input_create_key_pair"></a> [create\_key\_pair](#input\_create\_key\_pair) | Whether to create a new SSH key pair | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/integ/prod/sandbox) | `string` | n/a | yes |
| <a name="input_iam_inline_policies"></a> [iam\_inline\_policies](#input\_iam\_inline\_policies) | Map of inline policy name to policy JSON. If not provided, uses default permissions. | `map(string)` | `{}` | no |
| <a name="input_iam_managed_policy_arns"></a> [iam\_managed\_policy\_arns](#input\_iam\_managed\_policy\_arns) | List of AWS managed policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_keeper_ami_id"></a> [keeper\_ami\_id](#input\_keeper\_ami\_id) | AMI ID for Clickhouse keeper instances | `string` | n/a | yes |
| <a name="input_keeper_count"></a> [keeper\_count](#input\_keeper\_count) | Number of Clickhouse keeper nodes to create (can be 0 if using external keeper) | `number` | `3` | no |
| <a name="input_keeper_data2_device_name"></a> [keeper\_data2\_device\_name](#input\_keeper\_data2\_device\_name) | Device name for the keeper second data EBS volume | `string` | `"/dev/sdc"` | no |
| <a name="input_keeper_data2_volume_size"></a> [keeper\_data2\_volume\_size](#input\_keeper\_data2\_volume\_size) | Size of the second additional EBS volume in GB for Clickhouse keeper | `number` | `10` | no |
| <a name="input_keeper_data2_volume_type"></a> [keeper\_data2\_volume\_type](#input\_keeper\_data2\_volume\_type) | Type of the second additional EBS volume for keeper | `string` | `"gp3"` | no |
| <a name="input_keeper_data_device_name"></a> [keeper\_data\_device\_name](#input\_keeper\_data\_device\_name) | Device name for the keeper data EBS volume | `string` | `"/dev/sdb"` | no |
| <a name="input_keeper_data_volume_size"></a> [keeper\_data\_volume\_size](#input\_keeper\_data\_volume\_size) | Size of the additional EBS volume in GB for Clickhouse keeper data | `number` | `10` | no |
| <a name="input_keeper_data_volume_type"></a> [keeper\_data\_volume\_type](#input\_keeper\_data\_volume\_type) | Type of the additional EBS volume for keeper data | `string` | `"gp3"` | no |
| <a name="input_keeper_instance_type"></a> [keeper\_instance\_type](#input\_keeper\_instance\_type) | EC2 instance type for Clickhouse keepers | `string` | `"c7g.medium"` | no |
| <a name="input_keeper_root_volume_size"></a> [keeper\_root\_volume\_size](#input\_keeper\_root\_volume\_size) | Size of the keeper root EBS volume in GB | `number` | `30` | no |
| <a name="input_keeper_root_volume_type"></a> [keeper\_root\_volume\_type](#input\_keeper\_root\_volume\_type) | Type of the keeper root EBS volume | `string` | `"gp3"` | no |
| <a name="input_keeper_subnet_id"></a> [keeper\_subnet\_id](#input\_keeper\_subnet\_id) | Subnet ID for Clickhouse keeper instances and ENIs | `string` | n/a | yes |
| <a name="input_keeper_user_data_template"></a> [keeper\_user\_data\_template](#input\_keeper\_user\_data\_template) | Path to the keeper user data template file. If provided, the template will be processed with keeper\_ips and server\_ips variables. | `string` | `null` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name. Required if create\_key\_pair is false. | `string` | `null` | no |
| <a name="input_metadata_http_tokens"></a> [metadata\_http\_tokens](#input\_metadata\_http\_tokens) | IMDSv2 setting for EC2 instances - 'required' for IMDSv2 only, 'optional' for IMDSv1 and IMDSv2 | `string` | `"required"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | Public key material for creating new SSH key pair. If not provided when create\_key\_pair is true, a key pair will be auto-generated and stored in SSM | `string` | `null` | no |
| <a name="input_server_ami_id"></a> [server\_ami\_id](#input\_server\_ami\_id) | AMI ID for Clickhouse server instances | `string` | n/a | yes |
| <a name="input_server_count"></a> [server\_count](#input\_server\_count) | Number of Clickhouse server nodes to create | `number` | `2` | no |
| <a name="input_server_data2_device_name"></a> [server\_data2\_device\_name](#input\_server\_data2\_device\_name) | Device name for the server second data EBS volume | `string` | `"/dev/sdc"` | no |
| <a name="input_server_data2_volume_size"></a> [server\_data2\_volume\_size](#input\_server\_data2\_volume\_size) | Size of the second additional EBS volume in GB for Clickhouse server | `number` | `20` | no |
| <a name="input_server_data2_volume_type"></a> [server\_data2\_volume\_type](#input\_server\_data2\_volume\_type) | Type of the second additional EBS volume for server | `string` | `"gp3"` | no |
| <a name="input_server_data_device_name"></a> [server\_data\_device\_name](#input\_server\_data\_device\_name) | Device name for the server data EBS volume | `string` | `"/dev/sdb"` | no |
| <a name="input_server_data_volume_size"></a> [server\_data\_volume\_size](#input\_server\_data\_volume\_size) | Size of the additional EBS volume in GB for Clickhouse server data | `number` | `20` | no |
| <a name="input_server_data_volume_type"></a> [server\_data\_volume\_type](#input\_server\_data\_volume\_type) | Type of the additional EBS volume for server data | `string` | `"gp3"` | no |
| <a name="input_server_instance_type"></a> [server\_instance\_type](#input\_server\_instance\_type) | EC2 instance type for Clickhouse servers | `string` | `"r7g.large"` | no |
| <a name="input_server_root_volume_size"></a> [server\_root\_volume\_size](#input\_server\_root\_volume\_size) | Size of the server root EBS volume in GB | `number` | `200` | no |
| <a name="input_server_root_volume_type"></a> [server\_root\_volume\_type](#input\_server\_root\_volume\_type) | Type of the server root EBS volume | `string` | `"gp3"` | no |
| <a name="input_server_subnet_id"></a> [server\_subnet\_id](#input\_server\_subnet\_id) | Subnet ID for Clickhouse server instances and ENIs | `string` | n/a | yes |
| <a name="input_server_user_data_template"></a> [server\_user\_data\_template](#input\_server\_user\_data\_template) | Path to the server user data template file. If provided, the template will be processed with keeper\_ips and server\_ips variables. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#input\_vpc\_endpoint\_security\_group\_id) | Security group ID of VPC endpoints (for EC2 Metadata). If provided, HTTPS rules will be created. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer |
| <a name="output_alb_listener_arns"></a> [alb\_listener\_arns](#output\_alb\_listener\_arns) | ARNs of the ALB listeners |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | Security group ID used by the Clickhouse ALB |
| <a name="output_clickhouse_port"></a> [clickhouse\_port](#output\_clickhouse\_port) | Port used for Clickhouse HTTP interface |
| <a name="output_cluster_info"></a> [cluster\_info](#output\_cluster\_info) | Summary information about the Clickhouse cluster |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role for Clickhouse instances |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role for Clickhouse instances |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN of the IAM instance profile for Clickhouse instances |
| <a name="output_instance_profile_name"></a> [instance\_profile\_name](#output\_instance\_profile\_name) | Name of the IAM instance profile for Clickhouse instances |
| <a name="output_keeper_eni_ids"></a> [keeper\_eni\_ids](#output\_keeper\_eni\_ids) | IDs of the Clickhouse keeper network interfaces |
| <a name="output_keeper_eni_private_ips"></a> [keeper\_eni\_private\_ips](#output\_keeper\_eni\_private\_ips) | Private IP addresses of the Clickhouse keeper network interfaces |
| <a name="output_keeper_instance_ids"></a> [keeper\_instance\_ids](#output\_keeper\_instance\_ids) | IDs of the Clickhouse keeper EC2 instances |
| <a name="output_keeper_private_ips"></a> [keeper\_private\_ips](#output\_keeper\_private\_ips) | Private IP addresses of the Clickhouse keeper instances |
| <a name="output_keeper_security_group_id"></a> [keeper\_security\_group\_id](#output\_keeper\_security\_group\_id) | ID of the security group for Clickhouse keeper nodes |
| <a name="output_key_pair_id"></a> [key\_pair\_id](#output\_key\_pair\_id) | ID of the created key pair (if auto-generated) |
| <a name="output_key_pair_name"></a> [key\_pair\_name](#output\_key\_pair\_name) | Name of the SSH key pair used for Clickhouse instances |
| <a name="output_private_key_ssm_parameter"></a> [private\_key\_ssm\_parameter](#output\_private\_key\_ssm\_parameter) | SSM parameter name where private key is stored (if auto-generated) |
| <a name="output_server_eni_ids"></a> [server\_eni\_ids](#output\_server\_eni\_ids) | IDs of the Clickhouse server network interfaces |
| <a name="output_server_eni_private_ips"></a> [server\_eni\_private\_ips](#output\_server\_eni\_private\_ips) | Private IP addresses of the Clickhouse server network interfaces |
| <a name="output_server_instance_ids"></a> [server\_instance\_ids](#output\_server\_instance\_ids) | IDs of the Clickhouse server EC2 instances |
| <a name="output_server_private_ips"></a> [server\_private\_ips](#output\_server\_private\_ips) | Private IP addresses of the Clickhouse server instances |
| <a name="output_server_security_group_id"></a> [server\_security\_group\_id](#output\_server\_security\_group\_id) | ID of the security group for Clickhouse server nodes |
<!-- END_TF_DOCS -->