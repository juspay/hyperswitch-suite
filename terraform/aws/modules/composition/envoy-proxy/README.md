<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.29 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.29 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_asg"></a> [asg](#module\_asg) | terraform-aws-modules/autoscaling/aws | 9.2.0 |
| <a name="module_asg_security_group"></a> [asg\_security\_group](#module\_asg\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |
| <a name="module_envoy_iam_role"></a> [envoy\_iam\_role](#module\_envoy\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | ~> 5.0 |
| <a name="module_key_pair"></a> [key\_pair](#module\_key\_pair) | terraform-aws-modules/key-pair/aws | ~> 2.0 |
| <a name="module_lb_security_group"></a> [lb\_security\_group](#module\_lb\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_logs_bucket"></a> [logs\_bucket](#module\_logs\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_policy.cpu_target_tracking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.memory_target_tracking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_iam_instance_profile.envoy_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_launch_template.envoy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb_listener.envoy_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.envoy_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.custom_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.envoy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_s3_object.envoy_config_files](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group_rule.asg_ingress_from_alb_healthcheck](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.asg_ingress_from_alb_traffic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.existing_lb_to_asg_healthcheck](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.existing_lb_to_asg_traffic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_default_egress_to_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.envoy_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_wafv2_web_acl_association.envoy_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_role.existing_envoy_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_certificate_arns"></a> [additional\_certificate\_arns](#input\_additional\_certificate\_arns) | List of additional SSL certificate ARNs to attach to the HTTPS listener for SNI (Server Name Indication) support. Allows serving different certificates for different domains on the same listener. | `list(string)` | `[]` | no |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | List of additional IAM policy ARNs to attach to the Envoy IAM role (e.g., AmazonSSMManagedInstanceCore for SSM access) | `list(string)` | `[]` | no |
| <a name="input_alb_http_listener_port"></a> [alb\_http\_listener\_port](#input\_alb\_http\_listener\_port) | Port for ALB HTTP listener (port that ALB listens on for incoming HTTP traffic) | `number` | `80` | no |
| <a name="input_alb_https_listener_port"></a> [alb\_https\_listener\_port](#input\_alb\_https\_listener\_port) | Port for ALB HTTPS listener (port that ALB listens on for incoming HTTPS traffic) | `number` | `443` | no |
| <a name="input_config_bucket_arn"></a> [config\_bucket\_arn](#input\_config\_bucket\_arn) | ARN of S3 bucket containing Envoy configuration files (required if create\_config\_bucket=false) | `string` | `""` | no |
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | Name of S3 bucket containing Envoy configuration files (required if create\_config\_bucket=false) | `string` | `""` | no |
| <a name="input_config_files_source_path"></a> [config\_files\_source\_path](#input\_config\_files\_source\_path) | Local path to envoy config files to upload to S3 (only used if upload\_config\_to\_s3=true) | `string` | `"./config"` | no |
| <a name="input_create_config_bucket"></a> [create\_config\_bucket](#input\_create\_config\_bucket) | Whether to create a new S3 bucket for configuration files (if false, use existing bucket) | `bool` | `false` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Whether to create a new IAM role or use existing one | `bool` | `true` | no |
| <a name="input_create_instance_profile"></a> [create\_instance\_profile](#input\_create\_instance\_profile) | Whether to create a new instance profile for existing IAM role (only relevant when create\_iam\_role = false) | `bool` | `true` | no |
| <a name="input_create_lb"></a> [create\_lb](#input\_create\_lb) | Whether to create a new Load Balancer | `bool` | `true` | no |
| <a name="input_create_logs_bucket"></a> [create\_logs\_bucket](#input\_create\_logs\_bucket) | Whether to create a new S3 bucket for logs (if false, use existing bucket) | `bool` | `true` | no |
| <a name="input_create_target_group"></a> [create\_target\_group](#input\_create\_target\_group) | Whether to create a new target group | `bool` | `true` | no |
| <a name="input_custom_userdata"></a> [custom\_userdata](#input\_custom\_userdata) | Custom userdata script for Envoy instances. This should be environment-specific and loaded from the live layer (e.g., file("${path.module}/templates/userdata.sh")) | `string` | n/a | yes |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Map of concurrent Envoy deployments. Each key is an identifier (e.g., "v1", "v2").<br/>Traffic is split across them via ALB weighted forward.<br/><br/>- launch\_template\_id:      Optional. Provide to use an external launch template.<br/>- launch\_template\_version: Optional. Defaults to "$Latest" for external LTs,<br/>                           or the module-managed LT's latest\_version. | <pre>map(object({<br/>    asg_name                  = optional(string)<br/>    weight                    = number<br/>    desired_capacity          = optional(number)<br/>    launch_template_id        = optional(string)<br/>    launch_template_version   = string<br/>    target_group_name         = optional(string)<br/>    existing_target_group_arn = optional(string)<br/>  }))</pre> | <pre>{<br/>  "stable": {<br/>    "launch_template_version": "$Latest",<br/>    "weight": 100<br/>  }<br/>}</pre> | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of instances in ASG | `number` | `1` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | EKS cluster name (for envoy.yaml templating) | `string` | `""` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable auto-scaling policies for the ASG based on CPU and memory metrics | `bool` | `false` | no |
| <a name="input_enable_capacity_rebalance"></a> [enable\_capacity\_rebalance](#input\_enable\_capacity\_rebalance) | Enable capacity rebalancing for spot instances (launches replacement before termination) | `bool` | `false` | no |
| <a name="input_enable_http_to_https_redirect"></a> [enable\_http\_to\_https\_redirect](#input\_enable\_http\_to\_https\_redirect) | Enable automatic redirect from HTTP to HTTPS (requires enable\_https\_listener = true) | `bool` | `false` | no |
| <a name="input_enable_https_listener"></a> [enable\_https\_listener](#input\_enable\_https\_listener) | Enable HTTPS listener on port 443 with SSL/TLS termination | `bool` | `false` | no |
| <a name="input_enable_spot_instances"></a> [enable\_spot\_instances](#input\_enable\_spot\_instances) | Enable mixed instances policy with spot instances for cost optimization | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | Enable AWS WAF WebACL association with ALB | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_envoy_config_filename"></a> [envoy\_config\_filename](#input\_envoy\_config\_filename) | Name of the main Envoy config file (relative to config\_files\_source\_path).<br/>This file will receive template variable substitution when uploaded to S3.<br/>Different environments can use different filenames:<br/>- Dev: "envoy.yaml" or "envoy-dev.yaml"<br/>- Staging: "envoy-staging.yaml"<br/>- Production: "envoy-prod.yaml" or "proxy-config.yaml" | `string` | `"envoy.yaml"` | no |
| <a name="input_envoy_config_template"></a> [envoy\_config\_template](#input\_envoy\_config\_template) | Envoy configuration template content. This is environment-specific and flexible:<br/>- Load from file: file("${path.module}/config/my-envoy-config.yaml")<br/>- Load from any path: file("/path/to/envoy.yaml")<br/>- Provide inline: "admin: { ... }"<br/>- Use try() for optional: try(file("${path.module}/config/envoy.yaml"), "") | `string` | `""` | no |
| <a name="input_envoy_traffic_port"></a> [envoy\_traffic\_port](#input\_envoy\_traffic\_port) | Port where Envoy instances listen for traffic from ALB (target group port) - ALB forwards traffic to this port | `number` | `80` | no |
| <a name="input_envoy_upstream_port"></a> [envoy\_upstream\_port](#input\_envoy\_upstream\_port) | Port for Envoy to forward traffic to upstream (e.g., Internal ALB/Istio) | `number` | `80` | no |
| <a name="input_existing_iam_instance_profile_name"></a> [existing\_iam\_instance\_profile\_name](#input\_existing\_iam\_instance\_profile\_name) | Name of existing IAM instance profile to use (only if create\_iam\_role = false AND create\_instance\_profile = false) | `string` | `null` | no |
| <a name="input_existing_iam_role_name"></a> [existing\_iam\_role\_name](#input\_existing\_iam\_role\_name) | Name of existing IAM role to use (only if create\_iam\_role = false) | `string` | `null` | no |
| <a name="input_existing_lb_arn"></a> [existing\_lb\_arn](#input\_existing\_lb\_arn) | ARN of existing load balancer (optional - only needed if you want to reference it) | `string` | `null` | no |
| <a name="input_existing_lb_security_group_id"></a> [existing\_lb\_security\_group\_id](#input\_existing\_lb\_security\_group\_id) | Security group ID of existing load balancer (optional - only needed for automatic security group rule creation) | `string` | `null` | no |
| <a name="input_existing_tg_arn"></a> [existing\_tg\_arn](#input\_existing\_tg\_arn) | ARN of existing target group (required if create\_target\_group=false) | `string` | `null` | no |
| <a name="input_generate_ssh_key"></a> [generate\_ssh\_key](#input\_generate\_ssh\_key) | Whether to generate SSH key pair automatically. Note: Private key is NOT saved. Use SSM Session Manager for access. | `bool` | `true` | no |
| <a name="input_health_check"></a> [health\_check](#input\_health\_check) | Health check configuration for target group | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    port                = optional(number, 80)<br/>    path                = optional(string, "/healthz")<br/>    protocol            = optional(string, "HTTP")<br/>    matcher             = optional(string, "200")<br/>    interval            = optional(number, 30)<br/>    timeout             = optional(number, 5)<br/>    healthy_threshold   = optional(number, 2)<br/>    unhealthy_threshold = optional(number, 2)<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "healthy_threshold": 2,<br/>  "interval": 30,<br/>  "matcher": "200",<br/>  "path": "/healthz",<br/>  "port": 80,<br/>  "protocol": "HTTP",<br/>  "timeout": 5,<br/>  "unhealthy_threshold": 2<br/>}</pre> | no |
| <a name="input_hyperswitch_cloudfront_dns"></a> [hyperswitch\_cloudfront\_dns](#input\_hyperswitch\_cloudfront\_dns) | CloudFront distribution DNS for Hyperswitch (for envoy.yaml templating) | `string` | `""` | no |
| <a name="input_internal_loadbalancer_dns"></a> [internal\_loadbalancer\_dns](#input\_internal\_loadbalancer\_dns) | Internal load balancer DNS (for envoy.yaml templating) | `string` | `""` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key pair name (ignored if generate\_ssh\_key=true) | `string` | `null` | no |
| <a name="input_launch_template"></a> [launch\_template](#input\_launch\_template) | Launch template configuration. All fields control how module-managed<br/>launch templates are created. Ignored when a deployment provides its own<br/>launch\_template\_id. | <pre>object({<br/>    create = optional(bool, true)<br/>    # --- Compute ---<br/>    ami_id        = string<br/>    instance_type = optional(string, "t3.medium")<br/><br/>    # --- Versioning ---<br/>    update_default_version = optional(bool, true)<br/>    default_version        = optional(string, null)<br/><br/>    # --- EBS ---<br/>    ebs_optimized           = optional(bool, true)<br/>    enable_ebs_block_device = optional(bool, true)<br/>    ebs_encrypted           = optional(bool, true)<br/>    root_volume_size        = optional(number, 20)<br/>    root_volume_type        = optional(string, "gp3")<br/><br/>    # --- IMDS ---<br/>    imds_http_endpoint               = optional(string, null)<br/>    imds_http_tokens                 = optional(string, null)<br/>    imds_http_put_response_hop_limit = optional(number, null)<br/>    imds_instance_metadata_tags      = optional(string, null)<br/><br/>    # --- Monitoring ---<br/>    enable_detailed_monitoring = optional(bool, true)<br/>  })</pre> | n/a | yes |
| <a name="input_lb_egress_rules"></a> [lb\_egress\_rules](#input\_lb\_egress\_rules) | Additional egress rules for external load balancer security group. Use 'cidr' for IPv4, 'ipv6\_cidr' for IPv6, 'sg\_id' for security groups, or 'prefix\_list\_ids' for VPC endpoints | <pre>list(object({<br/>    description     = string<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string<br/>    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])<br/>    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])<br/>    sg_id           = optional(list(string)) # Security Group IDs<br/>    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])<br/>  }))</pre> | `[]` | no |
| <a name="input_lb_ingress_rules"></a> [lb\_ingress\_rules](#input\_lb\_ingress\_rules) | Additional ingress rules for external load balancer security group. Use 'cidr' for IPv4, 'ipv6\_cidr' for IPv6, 'sg\_id' for security groups, or 'prefix\_list\_ids' for VPC endpoints | <pre>list(object({<br/>    description     = string<br/>    from_port       = number<br/>    to_port         = number<br/>    protocol        = string<br/>    cidr            = optional(list(string)) # IPv4 CIDR blocks (e.g., ["0.0.0.0/0"])<br/>    ipv6_cidr       = optional(list(string)) # IPv6 CIDR blocks (e.g., ["::/0"])<br/>    sg_id           = optional(list(string)) # Security Group IDs<br/>    prefix_list_ids = optional(list(string)) # VPC Endpoint Prefix Lists (e.g., ["pl-6ea54007"])<br/>  }))</pre> | `[]` | no |
| <a name="input_lb_internal"></a> [lb\_internal](#input\_lb\_internal) | Whether the ALB is internal (true) or internet-facing (false) | `bool` | `false` | no |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | Subnet IDs for load balancer (public subnets for external ALB) | `list(string)` | n/a | yes |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Advanced listener rules for header-based routing, path-based routing, etc. | <pre>list(object({<br/>    priority = number<br/>    actions = list(object({<br/>      type             = string<br/>      target_group_arn = optional(string)<br/>      redirect = optional(object({<br/>        port        = string<br/>        protocol    = string<br/>        status_code = string<br/>      }))<br/>      fixed_response = optional(object({<br/>        content_type = string<br/>        message_body = optional(string)<br/>        status_code  = string<br/>      }))<br/>    }))<br/>    conditions = list(object({<br/>      host_header = optional(object({<br/>        values = list(string)<br/>      }))<br/>      http_header = optional(object({<br/>        http_header_name = string<br/>        values           = list(string)<br/>      }))<br/>      path_pattern = optional(object({<br/>        values = list(string)<br/>      }))<br/>      source_ip = optional(object({<br/>        values = list(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_bucket_arn"></a> [logs\_bucket\_arn](#input\_logs\_bucket\_arn) | ARN of existing S3 bucket for logs (required if create\_logs\_bucket=false) | `string` | `""` | no |
| <a name="input_logs_bucket_name"></a> [logs\_bucket\_name](#input\_logs\_bucket\_name) | Name of existing S3 bucket for logs (required if create\_logs\_bucket=false) | `string` | `""` | no |
| <a name="input_max_instance_lifetime"></a> [max\_instance\_lifetime](#input\_max\_instance\_lifetime) | Maximum lifetime of instances in seconds (0 = no limit, min 86400 = 24 hours) | `number` | `0` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances in ASG | `number` | `3` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances in ASG | `number` | `1` | no |
| <a name="input_on_demand_allocation_strategy"></a> [on\_demand\_allocation\_strategy](#input\_on\_demand\_allocation\_strategy) | Strategy for allocating on-demand instances (prioritized) | `string` | `"prioritized"` | no |
| <a name="input_on_demand_base_capacity"></a> [on\_demand\_base\_capacity](#input\_on\_demand\_base\_capacity) | Minimum number of on-demand instances to maintain (useful for baseline capacity) | `number` | `1` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_proxy_subnet_ids"></a> [proxy\_subnet\_ids](#input\_proxy\_subnet\_ids) | Subnet IDs for proxy instances (private subnets) | `list(string)` | n/a | yes |
| <a name="input_s3_vpc_endpoint_prefix_list_id"></a> [s3\_vpc\_endpoint\_prefix\_list\_id](#input\_s3\_vpc\_endpoint\_prefix\_list\_id) | Prefix list ID for S3 VPC endpoint (e.g., pl-6ea54007). If not provided, will use 0.0.0.0/0 for S3 access. | `string` | `null` | no |
| <a name="input_scaling_policies"></a> [scaling\_policies](#input\_scaling\_policies) | Configuration for auto-scaling policies using built-in AWS metrics | <pre>object({<br/>    # CPU-based target tracking<br/>    cpu_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target CPU utilization %<br/>    }), {})<br/><br/>    # Memory-based target tracking (requires CloudWatch agent on instances)<br/>    memory_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target Memory utilization %<br/>    }), {})<br/>  })</pre> | <pre>{<br/>  "cpu_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  },<br/>  "memory_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  }<br/>}</pre> | no |
| <a name="input_spot_allocation_strategy"></a> [spot\_allocation\_strategy](#input\_spot\_allocation\_strategy) | Strategy for allocating spot instances (lowest-price, capacity-optimized, capacity-optimized-prioritized) | `string` | `"capacity-optimized"` | no |
| <a name="input_spot_instance_percentage"></a> [spot\_instance\_percentage](#input\_spot\_instance\_percentage) | Percentage of spot instances in the ASG (0-100). Remaining will be on-demand. | `number` | `50` | no |
| <a name="input_ssl_certificate_arn"></a> [ssl\_certificate\_arn](#input\_ssl\_certificate\_arn) | ARN of SSL certificate for HTTPS listener (required if enable\_https\_listener = true) | `string` | `null` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | SSL policy for HTTPS listener | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_target_group_deregistration_delay"></a> [target\_group\_deregistration\_delay](#input\_target\_group\_deregistration\_delay) | Time to wait before deregistering a target in seconds | `number` | `30` | no |
| <a name="input_target_group_protocol"></a> [target\_group\_protocol](#input\_target\_group\_protocol) | Protocol for target group (HTTP or HTTPS) | `string` | `"HTTP"` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | List of policies to use when selecting instances to terminate (OldestLaunchTemplate, OldestInstance, Default, etc.) | `list(string)` | <pre>[<br/>  "OldestLaunchTemplate",<br/>  "OldestInstance",<br/>  "Default"<br/>]</pre> | no |
| <a name="input_upload_config_to_s3"></a> [upload\_config\_to\_s3](#input\_upload\_config\_to\_s3) | Whether to upload config files from local directory to S3 | `bool` | `false` | no |
| <a name="input_virtual_hosts_domains"></a> [virtual\_hosts\_domains](#input\_virtual\_hosts\_domains) | List of domain names for the Envoy virtual host (for envoy.yaml templating) | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | n/a | yes |
| <a name="input_waf_web_acl_arn"></a> [waf\_web\_acl\_arn](#input\_waf\_web\_acl\_arn) | ARN of AWS WAFv2 WebACL to associate with ALB (required if enable\_waf = true) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_ids"></a> [asg\_ids](#output\_asg\_ids) | Map of deployment names to Auto Scaling Group IDs |
| <a name="output_asg_names"></a> [asg\_names](#output\_asg\_names) | Map of deployment names to Auto Scaling Group names |
| <a name="output_asg_security_group_id"></a> [asg\_security\_group\_id](#output\_asg\_security\_group\_id) | Security group ID for ASG instances |
| <a name="output_config_bucket_arn"></a> [config\_bucket\_arn](#output\_config\_bucket\_arn) | ARN of the S3 bucket for configuration (created or existing) |
| <a name="output_config_bucket_created"></a> [config\_bucket\_created](#output\_config\_bucket\_created) | Whether config bucket was created by this module (true) or using existing (false) |
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the S3 bucket for configuration (created or existing) |
| <a name="output_config_version"></a> [config\_version](#output\_config\_version) | Current configuration version hash |
| <a name="output_deployment_weights"></a> [deployment\_weights](#output\_deployment\_weights) | Map of deployment names to ALB traffic weights |
| <a name="output_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#output\_iam\_instance\_profile\_name) | Name of the IAM instance profile (created or existing) |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role (created or existing) |
| <a name="output_iam_role_created"></a> [iam\_role\_created](#output\_iam\_role\_created) | Whether IAM role was created by this module (true) or using existing (false) |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role (created or existing) |
| <a name="output_launch_template_created"></a> [launch\_template\_created](#output\_launch\_template\_created) | Whether launch template was created by this module |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the module-managed launch template (null if not created) |
| <a name="output_lb_arn"></a> [lb\_arn](#output\_lb\_arn) | ARN of the Load Balancer |
| <a name="output_lb_dns_name"></a> [lb\_dns\_name](#output\_lb\_dns\_name) | DNS name of the Load Balancer (null if using existing LB) |
| <a name="output_lb_security_group_id"></a> [lb\_security\_group\_id](#output\_lb\_security\_group\_id) | Security group ID for load balancer (null if using existing LB) |
| <a name="output_lb_zone_id"></a> [lb\_zone\_id](#output\_lb\_zone\_id) | Zone ID of the Load Balancer (null if using existing LB) |
| <a name="output_logs_bucket_arn"></a> [logs\_bucket\_arn](#output\_logs\_bucket\_arn) | ARN of the S3 bucket for logs (created or existing) |
| <a name="output_logs_bucket_created"></a> [logs\_bucket\_created](#output\_logs\_bucket\_created) | Whether logs bucket was created by this module (true) or using existing (false) |
| <a name="output_logs_bucket_name"></a> [logs\_bucket\_name](#output\_logs\_bucket\_name) | Name of the S3 bucket for logs (created or existing) |
| <a name="output_ssh_key_generated"></a> [ssh\_key\_generated](#output\_ssh\_key\_generated) | Whether SSH key was auto-generated (true) or using existing key (false) |
| <a name="output_ssh_key_name"></a> [ssh\_key\_name](#output\_ssh\_key\_name) | Name of the SSH key pair |
| <a name="output_ssh_key_pair_id"></a> [ssh\_key\_pair\_id](#output\_ssh\_key\_pair\_id) | EC2 Key Pair ID (only if auto-generated) |
| <a name="output_ssh_key_parameter_name"></a> [ssh\_key\_parameter\_name](#output\_ssh\_key\_parameter\_name) | AWS Systems Manager Parameter Store name containing the private SSH key (only if auto-generated) |
| <a name="output_ssh_key_retrieval_command"></a> [ssh\_key\_retrieval\_command](#output\_ssh\_key\_retrieval\_command) | Command to retrieve the private SSH key from Parameter Store (only if auto-generated) |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | Map of deployment names to target group ARNs |
<!-- END_TF_DOCS -->