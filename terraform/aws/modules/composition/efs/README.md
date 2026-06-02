<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.32.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.32.1 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_efs"></a> [efs](#module\_efs) | terraform-aws-modules/efs/aws | 2.2.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev/sandbox/prod) | `string` | n/a | yes |
| <a name="input_file_systems"></a> [file\_systems](#input\_file\_systems) | Map of EFS file system configurations | <pre>map(object({<br/>    # Basic Configuration<br/>    name           = string<br/>    creation_token = optional(string)<br/><br/>    # Performance Configuration<br/>    performance_mode                = optional(string, "generalPurpose") # generalPurpose or maxIO<br/>    throughput_mode                 = optional(string, "bursting")       # bursting, provisioned, or elastic<br/>    provisioned_throughput_in_mibps = optional(number)                   # Required if throughput_mode is provisioned<br/><br/>    # Encryption<br/>    encrypted  = optional(bool, true)<br/>    kms_key_id = optional(string)<br/><br/>    # Lifecycle Policy (single object in v2.x)<br/>    lifecycle_policy = optional(object({<br/>      transition_to_ia                    = optional(string) # AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS<br/>      transition_to_primary_storage_class = optional(string) # AFTER_1_ACCESS<br/>      transition_to_archive               = optional(string) # AFTER_1_DAY, AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS, AFTER_180_DAYS, AFTER_270_DAYS, AFTER_365_DAYS<br/>    }))<br/><br/>    # Protection<br/>    replication_overwrite_protection = optional(string) # ENABLED, DISABLED, REPLICATING<br/><br/>    # Backup Policy<br/>    enable_backup_policy               = optional(bool, false)<br/>    backup_policy_status               = optional(string, "ENABLED") # ENABLED or DISABLED<br/>    file_system_policy                 = optional(string)<br/>    bypass_policy_lockout_safety_check = optional(bool, false)<br/><br/>    # Mount Targets<br/>    subnet_ids                = list(string)<br/>    security_group_ids        = optional(list(string), [])<br/>    mount_target_ip_addresses = optional(map(string), {}) # Map of subnet_id to IP address<br/><br/><br/>    # VPC Configuration (for module-created security group)<br/>    vpc_id = optional(string)<br/><br/>    # Security Group Rules (v2.x: separate ingress and egress)<br/>    security_group_ingress_rules = optional(map(object({<br/>      name                         = optional(string)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      description                  = optional(string)<br/>      from_port                    = optional(number, 2049)<br/>      ip_protocol                  = optional(string, "tcp")<br/>      prefix_list_id               = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      tags                         = optional(map(string), {})<br/>      to_port                      = optional(number, 2049)<br/>    })), {})<br/>    security_group_egress_rules = optional(map(object({<br/>      name                         = optional(string)<br/>      cidr_ipv4                    = optional(string)<br/>      cidr_ipv6                    = optional(string)<br/>      description                  = optional(string)<br/>      from_port                    = optional(number, 2049)<br/>      ip_protocol                  = optional(string, "tcp")<br/>      prefix_list_id               = optional(string)<br/>      referenced_security_group_id = optional(string)<br/>      tags                         = optional(map(string), {})<br/>      to_port                      = optional(number, 2049)<br/>    })), {})<br/><br/>    # Access Points<br/>    access_points = optional(map(object({<br/>      name = string<br/>      posix_user = optional(object({<br/>        gid            = number<br/>        uid            = number<br/>        secondary_gids = optional(list(number), [])<br/>      }))<br/>      root_directory = optional(object({<br/>        path = optional(string, "/")<br/>        creation_info = optional(object({<br/>          owner_gid   = number<br/>          owner_uid   = number<br/>          permissions = string<br/>        }))<br/>      }))<br/>      tags = optional(map(string), {})<br/>    })), {})<br/><br/>    # Replication Configuration<br/>    replication_configuration = optional(object({<br/>      destination_region                 = optional(string)<br/>      destination_file_system_id         = optional(string)<br/>      destination_availability_zone_name = optional(string)<br/>      destination_kms_key_id             = optional(string)<br/>    }))<br/><br/>    # Tags<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_point_arns"></a> [access\_point\_arns](#output\_access\_point\_arns) | Map of access point keys to ARNs |
| <a name="output_access_point_file_system_arns"></a> [access\_point\_file\_system\_arns](#output\_access\_point\_file\_system\_arns) | Map of access point keys to file system ARNs |
| <a name="output_access_point_ids"></a> [access\_point\_ids](#output\_access\_point\_ids) | Map of access point keys to IDs |
| <a name="output_file_system_arns"></a> [file\_system\_arns](#output\_file\_system\_arns) | Map of file system keys to ARNs |
| <a name="output_file_system_dns_names"></a> [file\_system\_dns\_names](#output\_file\_system\_dns\_names) | Map of file system keys to DNS names |
| <a name="output_file_system_ids"></a> [file\_system\_ids](#output\_file\_system\_ids) | Map of file system keys to IDs |
| <a name="output_mount_target_availability_zones"></a> [mount\_target\_availability\_zones](#output\_mount\_target\_availability\_zones) | Map of mount target keys to availability zones |
| <a name="output_mount_target_dns_names"></a> [mount\_target\_dns\_names](#output\_mount\_target\_dns\_names) | Map of mount target keys to DNS names |
| <a name="output_mount_target_ids"></a> [mount\_target\_ids](#output\_mount\_target\_ids) | Map of mount target keys to IDs |
| <a name="output_mount_target_ip_addresses"></a> [mount\_target\_ip\_addresses](#output\_mount\_target\_ip\_addresses) | Map of mount target keys to IP addresses |
| <a name="output_mount_target_network_interface_ids"></a> [mount\_target\_network\_interface\_ids](#output\_mount\_target\_network\_interface\_ids) | Map of mount target keys to network interface IDs |
| <a name="output_region"></a> [region](#output\_region) | AWS region where EFS resources are created |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Map of file system keys to their created security group IDs |
<!-- END_TF_DOCS -->