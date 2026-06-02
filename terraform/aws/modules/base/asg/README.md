<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.cpu_target_tracking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_autoscaling_policy.memory_target_tracking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_rebalance"></a> [capacity\_rebalance](#input\_capacity\_rebalance) | Enable capacity rebalancing for spot instances | `bool` | `false` | no |
| <a name="input_default_cooldown"></a> [default\_cooldown](#input\_default\_cooldown) | Time in seconds between scaling activities | `number` | `300` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of instances | `number` | `1` | no |
| <a name="input_enable_instance_refresh"></a> [enable\_instance\_refresh](#input\_enable\_instance\_refresh) | Enable automatic instance refresh when launch template changes | `bool` | `false` | no |
| <a name="input_enable_mixed_instances_policy"></a> [enable\_mixed\_instances\_policy](#input\_enable\_mixed\_instances\_policy) | Enable mixed instances policy for spot and on-demand instances | `bool` | `false` | no |
| <a name="input_enable_scaling_policies"></a> [enable\_scaling\_policies](#input\_enable\_scaling\_policies) | Enable auto-scaling policies for dynamic scaling based on CPU and Memory | `bool` | `false` | no |
| <a name="input_enabled_metrics"></a> [enabled\_metrics](#input\_enabled\_metrics) | List of metrics to enable for ASG | `list(string)` | <pre>[<br/>  "GroupMinSize",<br/>  "GroupMaxSize",<br/>  "GroupDesiredCapacity",<br/>  "GroupInServiceInstances",<br/>  "GroupTotalInstances"<br/>]</pre> | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | Time in seconds after instance comes into service before checking health | `number` | `300` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | Type of health check (EC2 or ELB) | `string` | `"EC2"` | no |
| <a name="input_instance_refresh_preferences"></a> [instance\_refresh\_preferences](#input\_instance\_refresh\_preferences) | Preferences for instance refresh behavior | <pre>object({<br/>    min_healthy_percentage       = optional(number, 50)<br/>    instance_warmup              = optional(number, 300)<br/>    max_healthy_percentage       = optional(number, 100)<br/>    checkpoint_percentages       = optional(list(number), [50])<br/>    checkpoint_delay             = optional(number, 300)<br/>    scale_in_protected_instances = optional(string, "Ignore")<br/>    standby_instances            = optional(string, "Ignore")<br/>  })</pre> | <pre>{<br/>  "checkpoint_delay": 300,<br/>  "checkpoint_percentages": [<br/>    50<br/>  ],<br/>  "instance_warmup": 300,<br/>  "max_healthy_percentage": 100,<br/>  "min_healthy_percentage": 50,<br/>  "scale_in_protected_instances": "Ignore",<br/>  "standby_instances": "Ignore"<br/>}</pre> | no |
| <a name="input_instance_refresh_triggers"></a> [instance\_refresh\_triggers](#input\_instance\_refresh\_triggers) | List of triggers that will start an instance refresh. Note: launch\_template changes always trigger refresh automatically. | `list(string)` | `[]` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Additional tags to apply to instances (will be propagated) | `map(string)` | `{}` | no |
| <a name="input_launch_template_id"></a> [launch\_template\_id](#input\_launch\_template\_id) | ID of the launch template to use | `string` | n/a | yes |
| <a name="input_launch_template_version"></a> [launch\_template\_version](#input\_launch\_template\_version) | Launch template version to use | `string` | `"$Latest"` | no |
| <a name="input_max_instance_lifetime"></a> [max\_instance\_lifetime](#input\_max\_instance\_lifetime) | Maximum lifetime of instances in seconds (0 = no limit) | `number` | `0` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances | `number` | `3` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances | `number` | `1` | no |
| <a name="input_mixed_instances_policy"></a> [mixed\_instances\_policy](#input\_mixed\_instances\_policy) | Configuration for mixed instances policy (spot + on-demand) | <pre>object({<br/>    on_demand_base_capacity                  = optional(number, 0)<br/>    on_demand_percentage_above_base_capacity = optional(number, 50)<br/>    spot_allocation_strategy                 = optional(string, "capacity-optimized")<br/>    spot_instance_pools                      = optional(number, 2)<br/>    spot_max_price                           = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "on_demand_base_capacity": 0,<br/>  "on_demand_percentage_above_base_capacity": 50,<br/>  "spot_allocation_strategy": "capacity-optimized",<br/>  "spot_instance_pools": 2,<br/>  "spot_max_price": ""<br/>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the Auto Scaling Group | `string` | n/a | yes |
| <a name="input_scaling_policies"></a> [scaling\_policies](#input\_scaling\_policies) | Configuration for auto-scaling policies using built-in AWS metrics | <pre>object({<br/>    # CPU-based target tracking<br/>    cpu_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target CPU utilization %<br/>    }), {})<br/><br/>    # Memory-based target tracking (requires CloudWatch agent on instances)<br/>    memory_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70.0) # Target Memory utilization %<br/>    }), {})<br/>  })</pre> | <pre>{<br/>  "cpu_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  },<br/>  "memory_target_tracking": {<br/>    "enabled": false,<br/>    "target_value": 70<br/>  }<br/>}</pre> | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ASG | `list(string)` | n/a | yes |
| <a name="input_suspended_processes"></a> [suspended\_processes](#input\_suspended\_processes) | List of processes to suspend | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_target_group_arns"></a> [target\_group\_arns](#input\_target\_group\_arns) | List of target group ARNs to attach | `list(string)` | `[]` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | List of policies to use for instance termination | `list(string)` | <pre>[<br/>  "Default"<br/>]</pre> | no |
| <a name="input_wait_for_capacity_timeout"></a> [wait\_for\_capacity\_timeout](#input\_wait\_for\_capacity\_timeout) | Maximum duration to wait for capacity | `string` | `"10m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_arn"></a> [asg\_arn](#output\_asg\_arn) | The ARN of the Auto Scaling Group |
| <a name="output_asg_availability_zones"></a> [asg\_availability\_zones](#output\_asg\_availability\_zones) | The availability zones of the Auto Scaling Group |
| <a name="output_asg_desired_capacity"></a> [asg\_desired\_capacity](#output\_asg\_desired\_capacity) | The desired capacity of the Auto Scaling Group |
| <a name="output_asg_id"></a> [asg\_id](#output\_asg\_id) | The Auto Scaling Group ID |
| <a name="output_asg_max_size"></a> [asg\_max\_size](#output\_asg\_max\_size) | The maximum size of the Auto Scaling Group |
| <a name="output_asg_min_size"></a> [asg\_min\_size](#output\_asg\_min\_size) | The minimum size of the Auto Scaling Group |
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | The Auto Scaling Group name |
| <a name="output_cpu_scaling_policy_arn"></a> [cpu\_scaling\_policy\_arn](#output\_cpu\_scaling\_policy\_arn) | ARN of the CPU target tracking scaling policy |
| <a name="output_cpu_scaling_policy_name"></a> [cpu\_scaling\_policy\_name](#output\_cpu\_scaling\_policy\_name) | Name of the CPU target tracking scaling policy |
| <a name="output_memory_scaling_policy_arn"></a> [memory\_scaling\_policy\_arn](#output\_memory\_scaling\_policy\_arn) | ARN of the memory target tracking scaling policy |
| <a name="output_memory_scaling_policy_name"></a> [memory\_scaling\_policy\_name](#output\_memory\_scaling\_policy\_name) | Name of the memory target tracking scaling policy |
<!-- END_TF_DOCS -->