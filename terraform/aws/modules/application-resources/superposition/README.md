<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_database"></a> [database](#module\_database) | git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/database | database-v0.1.4 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM assume role policy statements to append | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name | `string` | `"superposition"` | no |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root']) | `list(string)` | `[]` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | List of AWS managed policy names to attach | `list(string)` | `[]` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name) | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | Whether to create a database for Superposition | `bool` | `false` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | List of customer managed policy ARNs to attach | `list(string)` | `[]` | no |
| <a name="input_database_config"></a> [database\_config](#input\_database\_config) | Configuration object for the RDS Aurora PostgreSQL database | <pre>object({<br/>    vpc_id                                = string<br/>    subnet_ids                            = list(string)<br/>    cluster_identifier                    = optional(string, null)<br/>    cluster_identifier_prefix             = optional(string, null)<br/>    database_name                         = optional(string, null)<br/>    engine                                = optional(string, "aurora-postgresql")<br/>    engine_version                        = optional(string, null)<br/>    engine_mode                           = optional(string, "provisioned")<br/>    engine_lifecycle_support              = optional(string, "open-source-rds-extended-support")<br/>    cluster_scalability_type              = optional(string, null)<br/>    master_username                       = string<br/>    master_password                       = optional(string, null)<br/>    manage_master_user_password           = optional(bool, null)<br/>    master_user_secret_kms_key_id         = optional(string, null)<br/>    db_cluster_instance_class             = optional(string, null)<br/>    availability_zones                    = list(string)<br/>    allocated_storage                     = optional(number, null)<br/>    storage_type                          = optional(string, "aurora-iopt1")<br/>    iops                                  = optional(number, null)<br/>    network_type                          = optional(string, "IPV4")<br/>    port                                  = optional(number, 5432)<br/>    create_db_subnet_group                = optional(bool, true)<br/>    db_subnet_group_name                  = optional(string, null)<br/>    vpc_security_group_ids                = optional(list(string), [])<br/>    db_cluster_parameter_group_name       = optional(string, "default.aurora-postgresql17")<br/>    db_instance_parameter_group_name      = optional(string, null)<br/>    backup_retention_period               = optional(number, 7)<br/>    preferred_backup_window               = optional(string, "00:51-01:21")<br/>    preferred_maintenance_window          = optional(string, "thu:00:12-thu:00:42")<br/>    skip_final_snapshot                   = optional(bool, true)<br/>    final_snapshot_identifier             = optional(string, null)<br/>    snapshot_identifier                   = optional(string, null)<br/>    copy_tags_to_snapshot                 = optional(bool, false)<br/>    storage_encrypted                     = optional(bool, true)<br/>    kms_key_id                            = optional(string, null)<br/>    deletion_protection                   = optional(bool, false)<br/>    delete_automated_backups              = optional(bool, true)<br/>    iam_database_authentication_enabled   = optional(bool, false)<br/>    iam_roles                             = optional(list(string), [])<br/>    domain                                = optional(string, null)<br/>    domain_iam_role_name                  = optional(string, null)<br/>    allow_major_version_upgrade           = optional(bool, null)<br/>    apply_immediately                     = optional(bool, null)<br/>    enabled_cloudwatch_logs_exports       = optional(list(string), ["postgresql"])<br/>    performance_insights_enabled          = optional(bool, false)<br/>    performance_insights_kms_key_id       = optional(string, null)<br/>    performance_insights_retention_period = optional(number, 0)<br/>    monitoring_interval                   = optional(number, 0)<br/>    monitoring_role_arn                   = optional(string, null)<br/>    database_insights_mode                = optional(string, "standard")<br/>    enable_http_endpoint                  = optional(bool, false)<br/>    enable_local_write_forwarding         = optional(bool, null)<br/>    replication_source_identifier         = optional(string, null)<br/>    source_region                         = optional(string, null)<br/>    backtrack_window                      = optional(number, 0)<br/>    ca_certificate_identifier             = optional(string, null)<br/>    db_system_id                          = optional(string, null)<br/>    create_security_group                 = optional(bool, true)<br/>    security_group_name                   = optional(string, null)<br/>    security_group_description            = optional(string, null)<br/>    scaling_configuration                 = optional(any, null)<br/>    serverlessv2_scaling_configuration    = optional(any, null)<br/>    restore_to_point_in_time              = optional(any, null)<br/>    s3_import                             = optional(any, null)<br/>    create_global_cluster                 = optional(bool, false)<br/>    global_cluster_identifier             = optional(string, null)<br/>    global_deletion_protection            = optional(bool, true)<br/>    enable_global_write_forwarding        = optional(bool, false)<br/>    use_existing_as_global_primary        = optional(bool, false)<br/>    source_db_cluster_identifier          = optional(string, null)<br/>    create_custom_parameter_group         = optional(bool, false)<br/>    custom_parameter_group_name           = optional(string, null)<br/>    custom_parameter_group_family         = optional(string, null)<br/>    custom_parameter_group_description    = optional(string, null)<br/>    custom_parameter_group_parameters     = optional(list(map(string)), [])<br/>    cluster_instances = optional(map(object({<br/>      identifier                            = optional(string)<br/>      identifier_prefix                     = optional(string)<br/>      instance_class                        = string<br/>      engine                                = optional(string)<br/>      engine_version                        = optional(string)<br/>      publicly_accessible                   = optional(bool)<br/>      db_parameter_group_name               = optional(string)<br/>      apply_immediately                     = optional(bool)<br/>      monitoring_role_arn                   = optional(string)<br/>      monitoring_interval                   = optional(number)<br/>      promotion_tier                        = optional(number)<br/>      availability_zone                     = optional(string)<br/>      preferred_backup_window               = optional(string)<br/>      preferred_maintenance_window          = optional(string)<br/>      auto_minor_version_upgrade            = optional(bool)<br/>      performance_insights_enabled          = optional(bool)<br/>      performance_insights_kms_key_id       = optional(string)<br/>      performance_insights_retention_period = optional(number)<br/>      copy_tags_to_snapshot                 = optional(bool)<br/>      ca_cert_identifier                    = optional(string)<br/>      custom_iam_instance_profile           = optional(string)<br/>      force_destroy                         = optional(bool)<br/>      tags                                  = optional(map(string))<br/>    })), {})<br/>    tags = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching policies when destroying the role | `bool` | `true` | no |
| <a name="input_inline_policies"></a> [inline\_policies](#input\_inline\_policies) | Map of inline policies for role-specific permissions | `map(string)` | `{}` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the role (in seconds) | `number` | `3600` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_assume_role_principals_enabled"></a> [assume\_role\_principals\_enabled](#output\_assume\_role\_principals\_enabled) | Whether assume role principals feature is enabled |
| <a name="output_aws_managed_policies_enabled"></a> [aws\_managed\_policies\_enabled](#output\_aws\_managed\_policies\_enabled) | Whether AWS managed policy attachments feature is enabled |
| <a name="output_customer_managed_policies_enabled"></a> [customer\_managed\_policies\_enabled](#output\_customer\_managed\_policies\_enabled) | Whether customer managed policy attachments feature is enabled |
| <a name="output_database_cluster_arn"></a> [database\_cluster\_arn](#output\_database\_cluster\_arn) | ARN of the RDS cluster (if database is created) |
| <a name="output_database_cluster_id"></a> [database\_cluster\_id](#output\_database\_cluster\_id) | RDS Cluster Identifier (if database is created) |
| <a name="output_database_cluster_instance_endpoints"></a> [database\_cluster\_instance\_endpoints](#output\_database\_cluster\_instance\_endpoints) | Map of cluster instance endpoints (if database is created) |
| <a name="output_database_cluster_instance_ids"></a> [database\_cluster\_instance\_ids](#output\_database\_cluster\_instance\_ids) | Map of cluster instance identifiers (if database is created) |
| <a name="output_database_enabled"></a> [database\_enabled](#output\_database\_enabled) | Whether database feature is enabled |
| <a name="output_database_endpoint"></a> [database\_endpoint](#output\_database\_endpoint) | Writer endpoint for the database (if database is created) |
| <a name="output_database_master_username"></a> [database\_master\_username](#output\_database\_master\_username) | Master username for the database (if database is created) |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the database (if database is created) |
| <a name="output_database_port"></a> [database\_port](#output\_database\_port) | Port for the database (if database is created) |
| <a name="output_database_reader_endpoint"></a> [database\_reader\_endpoint](#output\_database\_reader\_endpoint) | Reader endpoint for the database (if database is created) |
| <a name="output_database_security_group_id"></a> [database\_security\_group\_id](#output\_database\_security\_group\_id) | ID of the security group for the database (if created) |
| <a name="output_inline_policies_enabled"></a> [inline\_policies\_enabled](#output\_inline\_policies\_enabled) | Whether inline policies feature is enabled |
| <a name="output_oidc_enabled"></a> [oidc\_enabled](#output\_oidc\_enabled) | Whether OIDC/IRSA feature is enabled |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role for Superposition application |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the IAM role for Superposition application |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role for Superposition application |
<!-- END_TF_DOCS -->