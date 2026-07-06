<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_asg"></a> [asg](#module\_asg) | ../../base/asg | n/a |
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | ../../base/s3-bucket | n/a |
| <a name="module_launch_template"></a> [launch\_template](#module\_launch\_template) | ../../base/launch-template | n/a |
| <a name="module_logs_bucket"></a> [logs\_bucket](#module\_logs\_bucket) | ../../base/s3-bucket | n/a |
| <a name="module_nlb"></a> [nlb](#module\_nlb) | ../../base/nlb | n/a |
| <a name="module_nlb_listener_tcp"></a> [nlb\_listener\_tcp](#module\_nlb\_listener\_tcp) | ../../base/nlb-listener | n/a |
| <a name="module_nlb_listener_tls"></a> [nlb\_listener\_tls](#module\_nlb\_listener\_tls) | ../../base/nlb-listener | n/a |
| <a name="module_squid_iam_role"></a> [squid\_iam\_role](#module\_squid\_iam\_role) | ../../base/iam-role | n/a |
| <a name="module_target_group"></a> [target\_group](#module\_target\_group) | ../../base/target-group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.squid_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_key_pair.squid_key_pair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_object.squid_config_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.nlb_health_checks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.nlb_to_squid_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.squid_from_nlb_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.squid_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [tls_private_key.squid](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_role.existing_squid_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_subnet.lb_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | List of additional IAM policy ARNs to attach to the Squid IAM role (e.g., AmazonSSMManagedInstanceCore for SSM access) | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for Squid instances (ignored if use\_existing\_launch\_template = true) | `string` | `null` | no |
| <a name="input_config_bucket_arn"></a> [config\_bucket\_arn](#input\_config\_bucket\_arn) | ARN of S3 bucket containing Squid configuration files (required if create\_config\_bucket=false) | `string` | `""` | no |
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | Name of S3 bucket containing Squid configuration files (required if create\_config\_bucket=false) | `string` | `""` | no |
| <a name="input_config_files"></a> [config\_files](#input\_config\_files) | Map of Squid config files to upload to S3. The key is the object key name (uploaded as <s3\_config\_path\_prefix>/<key>) and the value is the local file path. Only used if upload\_config\_to\_s3=true. | `map(string)` | `{}` | no |
| <a name="input_configure_root_volume"></a> [configure\_root\_volume](#input\_configure\_root\_volume) | Whether to explicitly configure root volume. If false, uses AMI defaults (not recommended) | `bool` | `true` | no |
| <a name="input_create_config_bucket"></a> [create\_config\_bucket](#input\_create\_config\_bucket) | Whether to create a new S3 bucket for configuration files (if false, use existing bucket) | `bool` | `false` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Whether to create a new IAM role or use existing one | `bool` | `true` | no |
| <a name="input_create_instance_profile"></a> [create\_instance\_profile](#input\_create\_instance\_profile) | Whether to create a new instance profile for existing IAM role (only relevant when create\_iam\_role = false) | `bool` | `true` | no |
| <a name="input_create_logs_bucket"></a> [create\_logs\_bucket](#input\_create\_logs\_bucket) | Whether to create a new S3 bucket for logs (if false, use existing bucket) | `bool` | `true` | no |
| <a name="input_create_nlb"></a> [create\_nlb](#input\_create\_nlb) | Whether to create a new Network Load Balancer | `bool` | `true` | no |
| <a name="input_create_target_group"></a> [create\_target\_group](#input\_create\_target\_group) | Whether to create a new target group | `bool` | `true` | no |
| <a name="input_custom_userdata"></a> [custom\_userdata](#input\_custom\_userdata) | Custom userdata script for Squid instances. Should be base64 encoded or plain text. | `string` | n/a | yes |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of instances in ASG | `number` | `1` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable auto-scaling policies for the ASG based on CPU and memory metrics | `bool` | `false` | no |
| <a name="input_enable_capacity_rebalance"></a> [enable\_capacity\_rebalance](#input\_enable\_capacity\_rebalance) | Enable capacity rebalancing for spot instances. When enabled, ASG proactively replaces spot instances before they are interrupted. | `bool` | `false` | no |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | Enable detailed CloudWatch monitoring | `bool` | `true` | no |
| <a name="input_enable_instance_refresh"></a> [enable\_instance\_refresh](#input\_enable\_instance\_refresh) | Enable automatic instance refresh when launch template changes. When enabled, ASG will automatically replace instances with manual checkpoints for validation. | `bool` | `false` | no |
| <a name="input_enable_spot_instances"></a> [enable\_spot\_instances](#input\_enable\_spot\_instances) | Enable mixed instances policy with spot instances for cost optimization | `bool` | `false` | no |
| <a name="input_enable_tcp_listener"></a> [enable\_tcp\_listener](#input\_enable\_tcp\_listener) | Enable TCP listener on the NLB (typically port 80 or 3128) | `bool` | `true` | no |
| <a name="input_enable_tls_listener"></a> [enable\_tls\_listener](#input\_enable\_tls\_listener) | Enable TLS listener on port 443 for encrypted proxy connections | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_existing_iam_instance_profile_name"></a> [existing\_iam\_instance\_profile\_name](#input\_existing\_iam\_instance\_profile\_name) | Name of existing IAM instance profile to use (only if create\_iam\_role = false AND create\_instance\_profile = false) | `string` | `null` | no |
| <a name="input_existing_iam_role_name"></a> [existing\_iam\_role\_name](#input\_existing\_iam\_role\_name) | Name of existing IAM role to use (only if create\_iam\_role = false) | `string` | `null` | no |
| <a name="input_existing_launch_template_id"></a> [existing\_launch\_template\_id](#input\_existing\_launch\_template\_id) | ID of existing launch template to use (required if use\_existing\_launch\_template = true) | `string` | `null` | no |
| <a name="input_existing_launch_template_version"></a> [existing\_launch\_template\_version](#input\_existing\_launch\_template\_version) | Version of existing launch template to use ($Latest, $Default, or specific version number) | `string` | `"$Latest"` | no |
| <a name="input_existing_lb_arn"></a> [existing\_lb\_arn](#input\_existing\_lb\_arn) | ARN of existing load balancer (required if create\_nlb=false) | `string` | `null` | no |
| <a name="input_existing_lb_listener_arn"></a> [existing\_lb\_listener\_arn](#input\_existing\_lb\_listener\_arn) | ARN of existing load balancer listener (required if create\_nlb=false and attaching via listener rule) | `string` | `null` | no |
| <a name="input_existing_tg_arn"></a> [existing\_tg\_arn](#input\_existing\_tg\_arn) | ARN of existing target group (required if create\_target\_group=false) | `string` | `null` | no |
| <a name="input_generate_ssh_key"></a> [generate\_ssh\_key](#input\_generate\_ssh\_key) | Whether to generate SSH key pair automatically. Note: Private key is NOT saved. Use SSM Session Manager for access. | `bool` | `true` | no |
| <a name="input_instance_refresh_preferences"></a> [instance\_refresh\_preferences](#input\_instance\_refresh\_preferences) | Preferences for instance refresh behavior. Defines how instances are replaced during a refresh. | <pre>object({<br/>    min_healthy_percentage       = optional(number, 50)<br/>    instance_warmup              = optional(number, 300)<br/>    max_healthy_percentage       = optional(number, 100)<br/>    checkpoint_percentages       = optional(list(number), [50])<br/>    checkpoint_delay             = optional(number, 300)<br/>    scale_in_protected_instances = optional(string, "Ignore")<br/>    standby_instances            = optional(string, "Ignore")<br/>  })</pre> | <pre>{<br/>  "checkpoint_delay": 300,<br/>  "checkpoint_percentages": [<br/>    50<br/>  ],<br/>  "instance_warmup": 300,<br/>  "max_healthy_percentage": 100,<br/>  "min_healthy_percentage": 50,<br/>  "scale_in_protected_instances": "Ignore",<br/>  "standby_instances": "Ignore"<br/>}</pre> | no |
| <a name="input_instance_refresh_triggers"></a> [instance\_refresh\_triggers](#input\_instance\_refresh\_triggers) | List of triggers that will start an instance refresh. Note: launch\_template changes always trigger refresh automatically. | `list(string)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for Squid proxy (ignored if use\_existing\_launch\_template = true) | `string` | `"t3.medium"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name (ignored if generate\_ssh\_key=true) | `string` | `null` | no |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | Subnet IDs for load balancer (service layer subnets) | `list(string)` | n/a | yes |
| <a name="input_logs_bucket_arn"></a> [logs\_bucket\_arn](#input\_logs\_bucket\_arn) | ARN of existing S3 bucket for logs (required if create\_logs\_bucket=false) | `string` | `""` | no |
| <a name="input_logs_bucket_name"></a> [logs\_bucket\_name](#input\_logs\_bucket\_name) | Name of existing S3 bucket for logs (required if create\_logs\_bucket=false) | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances in ASG | `number` | `3` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances in ASG | `number` | `1` | no |
| <a name="input_name_override"></a> [name\_override](#input\_name\_override) | Override for resource name prefix (appended to environment and project name) | `string` | `"squid"` | no |
| <a name="input_on_demand_base_capacity"></a> [on\_demand\_base\_capacity](#input\_on\_demand\_base\_capacity) | Minimum number of on-demand instances to maintain (useful for baseline capacity) | `number` | `0` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_proxy_subnet_ids"></a> [proxy\_subnet\_ids](#input\_proxy\_subnet\_ids) | Subnet IDs for proxy instances (private subnets with NAT) | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for resource deployment. Passed from live layer to ensure correct region configuration. | `string` | n/a | yes |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size of root EBS volume in GB (only used if configure\_root\_volume=true) | `number` | `30` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of root EBS volume (only used if configure\_root\_volume=true) | `string` | `"gp3"` | no |
| <a name="input_s3_config_path_prefix"></a> [s3\_config\_path\_prefix](#input\_s3\_config\_path\_prefix) | S3 path prefix for squid config files to upload (only used if upload\_config\_to\_s3=true) | `string` | `"squid"` | no |
| <a name="input_scaling_policies"></a> [scaling\_policies](#input\_scaling\_policies) | Configuration for auto-scaling policies using built-in AWS metrics | <pre>object({<br/>    # CPU-based target tracking<br/>    cpu_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target CPU utilization %<br/>    }), {})<br/><br/>    # Memory-based target tracking (requires CloudWatch agent on instances)<br/>    memory_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target Memory utilization %<br/>    }), {})<br/>  })</pre> | <pre>{<br/>  "cpu_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  },<br/>  "memory_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  }<br/>}</pre> | no |
| <a name="input_spot_allocation_strategy"></a> [spot\_allocation\_strategy](#input\_spot\_allocation\_strategy) | Strategy for allocating spot instances (lowest-price, capacity-optimized, capacity-optimized-prioritized) | `string` | `"capacity-optimized"` | no |
| <a name="input_spot_instance_percentage"></a> [spot\_instance\_percentage](#input\_spot\_instance\_percentage) | Percentage of spot instances in the ASG (0-100). Remaining will be on-demand. | `number` | `50` | no |
| <a name="input_squid_port"></a> [squid\_port](#input\_squid\_port) | Port for Squid proxy | `number` | `3128` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_tcp_listener_port"></a> [tcp\_listener\_port](#input\_tcp\_listener\_port) | Port for TCP listener (if enable\_tcp\_listener=true) | `number` | `80` | no |
| <a name="input_tls_alpn_policy"></a> [tls\_alpn\_policy](#input\_tls\_alpn\_policy) | ALPN policy for TLS listener. Options: None, HTTP2Preferred, HTTP2Only | `string` | `"None"` | no |
| <a name="input_tls_certificate_arn"></a> [tls\_certificate\_arn](#input\_tls\_certificate\_arn) | ARN of ACM certificate for TLS listener (required if enable\_tls\_listener=true) | `string` | `null` | no |
| <a name="input_tls_listener_port"></a> [tls\_listener\_port](#input\_tls\_listener\_port) | Port for TLS listener (if enable\_tls\_listener=true) | `number` | `443` | no |
| <a name="input_tls_ssl_policy"></a> [tls\_ssl\_policy](#input\_tls\_ssl\_policy) | SSL policy for TLS listener. Use ELBSecurityPolicy-TLS13-1-2-2021-06 for TLS 1.3 + 1.2 support | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_upload_config_to_s3"></a> [upload\_config\_to\_s3](#input\_upload\_config\_to\_s3) | Whether to upload config files from local directory to S3 | `bool` | `false` | no |
| <a name="input_use_existing_launch_template"></a> [use\_existing\_launch\_template](#input\_use\_existing\_launch\_template) | Whether to use an existing launch template instead of creating a new one | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_id"></a> [asg\_id](#output\_asg\_id) | ID of the Auto Scaling Group |
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | Name of the Auto Scaling Group |
| <a name="output_asg_security_group_id"></a> [asg\_security\_group\_id](#output\_asg\_security\_group\_id) | Security group ID for ASG instances |
| <a name="output_autoscaling_enabled"></a> [autoscaling\_enabled](#output\_autoscaling\_enabled) | Whether auto-scaling policies are enabled |
| <a name="output_config_bucket_arn"></a> [config\_bucket\_arn](#output\_config\_bucket\_arn) | ARN of the S3 bucket for configuration (created or existing) |
| <a name="output_config_bucket_created"></a> [config\_bucket\_created](#output\_config\_bucket\_created) | Whether config bucket was created by this module (true) or using existing (false) |
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the S3 bucket for configuration (created or existing) |
| <a name="output_cpu_scaling_policy_arn"></a> [cpu\_scaling\_policy\_arn](#output\_cpu\_scaling\_policy\_arn) | ARN of the CPU target tracking scaling policy (null if not enabled) |
| <a name="output_cpu_scaling_policy_name"></a> [cpu\_scaling\_policy\_name](#output\_cpu\_scaling\_policy\_name) | Name of the CPU target tracking scaling policy (null if not enabled) |
| <a name="output_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#output\_iam\_instance\_profile\_name) | Name of the IAM instance profile (created or existing) |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role (created or existing) |
| <a name="output_iam_role_created"></a> [iam\_role\_created](#output\_iam\_role\_created) | Whether IAM role was created by this module (true) or using existing (false) |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role (created or existing) |
| <a name="output_launch_template_created"></a> [launch\_template\_created](#output\_launch\_template\_created) | Whether launch template was created by this module (true) or using existing (false) |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the launch template (created or existing) |
| <a name="output_launch_template_version"></a> [launch\_template\_version](#output\_launch\_template\_version) | Version of the launch template being used |
| <a name="output_logs_bucket_arn"></a> [logs\_bucket\_arn](#output\_logs\_bucket\_arn) | ARN of the S3 bucket for logs (created or existing) |
| <a name="output_logs_bucket_created"></a> [logs\_bucket\_created](#output\_logs\_bucket\_created) | Whether logs bucket was created by this module (true) or using existing (false) |
| <a name="output_logs_bucket_name"></a> [logs\_bucket\_name](#output\_logs\_bucket\_name) | Name of the S3 bucket for logs (created or existing) |
| <a name="output_memory_scaling_policy_arn"></a> [memory\_scaling\_policy\_arn](#output\_memory\_scaling\_policy\_arn) | ARN of the memory target tracking scaling policy (null if not enabled) |
| <a name="output_memory_scaling_policy_name"></a> [memory\_scaling\_policy\_name](#output\_memory\_scaling\_policy\_name) | Name of the memory target tracking scaling policy (null if not enabled) |
| <a name="output_nlb_arn"></a> [nlb\_arn](#output\_nlb\_arn) | ARN of the Network Load Balancer |
| <a name="output_nlb_dns_name"></a> [nlb\_dns\_name](#output\_nlb\_dns\_name) | DNS name of the Network Load Balancer |
| <a name="output_nlb_security_group_id"></a> [nlb\_security\_group\_id](#output\_nlb\_security\_group\_id) | Security group ID for Network Load Balancer (null if NLB not created) |
| <a name="output_nlb_zone_id"></a> [nlb\_zone\_id](#output\_nlb\_zone\_id) | Zone ID of the Network Load Balancer |
| <a name="output_proxy_endpoints"></a> [proxy\_endpoints](#output\_proxy\_endpoints) | Proxy endpoints for EKS pods to use |
| <a name="output_scaling_policies_summary"></a> [scaling\_policies\_summary](#output\_scaling\_policies\_summary) | Summary of enabled scaling policies |
| <a name="output_ssh_key_generated"></a> [ssh\_key\_generated](#output\_ssh\_key\_generated) | Whether SSH key was auto-generated (true) or using existing key (false) |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | Name of the SSH key pair |
| <a name="output_ssh_key_pair_id"></a> [ssh\_key\_pair\_id](#output\_ssh\_key\_pair\_id) | EC2 Key Pair ID (only if auto-generated) |
| <a name="output_ssh_key_parameter_name"></a> [ssh\_key\_parameter\_name](#output\_ssh\_key\_parameter\_name) | AWS Systems Manager Parameter Store name containing the private SSH key (only if auto-generated) |
| <a name="output_ssh_key_retrieval_command"></a> [ssh\_key\_retrieval\_command](#output\_ssh\_key\_retrieval\_command) | Command to retrieve the private SSH key from Parameter Store (only if auto-generated) |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | ARN of the target group |
| <a name="output_tcp_listener_arn"></a> [tcp\_listener\_arn](#output\_tcp\_listener\_arn) | ARN of the TCP listener (null if not created) |
| <a name="output_tls_listener_arn"></a> [tls\_listener\_arn](#output\_tls\_listener\_arn) | ARN of the TLS listener (null if not created) |
<!-- END_TF_DOCS -->