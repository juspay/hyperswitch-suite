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
| <a name="module_elasticache"></a> [elasticache](#module\_elasticache) | git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/elasticache | elasticache-v0.1.4 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.inline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.lb_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM assume role policy statements to append | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name | `string` | `"ratelimiter"` | no |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root']) | `list(string)` | `[]` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | List of AWS managed policy names to attach | `list(string)` | `[]` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name) | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_create_lb_security_group"></a> [create\_lb\_security\_group](#input\_create\_lb\_security\_group) | Whether to create a security group for the load balancer | `bool` | `false` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | List of customer managed policy ARNs to attach | `list(string)` | `[]` | no |
| <a name="input_elasticache_config"></a> [elasticache\_config](#input\_elasticache\_config) | ElastiCache configuration for rate limiter | <pre>object({<br/>    enabled                          = optional(bool, true)<br/>    elasticache_replication_group_id = optional(string, null)<br/>    subnet_ids                       = optional(list(string), [])<br/>    engine                           = optional(string, "valkey")<br/>    engine_version                   = optional(string, "8.2")<br/>    parameter_group_name             = optional(string, "default.valkey8")<br/>    port                             = optional(number, 6379)<br/>    node_type                        = optional(string, "cache.t3.small")<br/>    num_cache_clusters               = optional(number, 2)<br/>    num_node_groups                  = optional(number, null)<br/>    replicas_per_node_group          = optional(number, null)<br/>    cluster_mode                     = optional(string, "disabled")<br/>    automatic_failover_enabled       = optional(bool, true)<br/>    multi_az_enabled                 = optional(bool, true)<br/>    at_rest_encryption_enabled       = optional(bool, true)<br/>    transit_encryption_enabled       = optional(bool, false)<br/>    auth_token                       = optional(string, null)<br/>    create_subnet_group              = optional(bool, true)<br/>    subnet_group_name                = optional(string, null)<br/>    create_security_group            = optional(bool, true)<br/>    existing_security_group_ids      = optional(list(string), [])<br/>    maintenance_window               = optional(string, "sun:05:00-sun:06:00")<br/>    snapshot_window                  = optional(string, "03:00-05:00")<br/>    snapshot_retention_limit         = optional(number, 1)<br/>    apply_immediately                = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching policies when destroying the role | `bool` | `true` | no |
| <a name="input_inline_policies"></a> [inline\_policies](#input\_inline\_policies) | Map of inline policies for role-specific permissions | `map(string)` | `{}` | no |
| <a name="input_lb_egress_rules"></a> [lb\_egress\_rules](#input\_lb\_egress\_rules) | Egress rules for load balancer security group | <pre>map(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | `{}` | no |
| <a name="input_lb_ingress_rules"></a> [lb\_ingress\_rules](#input\_lb\_ingress\_rules) | Ingress rules for load balancer security group | <pre>map(object({<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    cidr_blocks = list(string)<br/>    description = string<br/>  }))</pre> | `{}` | no |
| <a name="input_lb_security_group_description"></a> [lb\_security\_group\_description](#input\_lb\_security\_group\_description) | Description for the load balancer security group | `string` | `"Security group for rate limiter load balancer"` | no |
| <a name="input_lb_security_group_name"></a> [lb\_security\_group\_name](#input\_lb\_security\_group\_name) | Name of the load balancer security group | `string` | `null` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the role (in seconds) | `number` | `3600` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where resources will be created | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_assume_role_principals_enabled"></a> [assume\_role\_principals\_enabled](#output\_assume\_role\_principals\_enabled) | Whether assume role principals feature is enabled |
| <a name="output_aws_managed_policies_enabled"></a> [aws\_managed\_policies\_enabled](#output\_aws\_managed\_policies\_enabled) | Whether AWS managed policy attachments feature is enabled |
| <a name="output_customer_managed_policies_enabled"></a> [customer\_managed\_policies\_enabled](#output\_customer\_managed\_policies\_enabled) | Whether customer managed policy attachments feature is enabled |
| <a name="output_elasticache_connection_info"></a> [elasticache\_connection\_info](#output\_elasticache\_connection\_info) | Connection information for the ElastiCache cluster |
| <a name="output_elasticache_enabled"></a> [elasticache\_enabled](#output\_elasticache\_enabled) | Whether ElastiCache feature is enabled |
| <a name="output_elasticache_port"></a> [elasticache\_port](#output\_elasticache\_port) | Port number for the replication group |
| <a name="output_elasticache_primary_endpoint_address"></a> [elasticache\_primary\_endpoint\_address](#output\_elasticache\_primary\_endpoint\_address) | Address of the primary endpoint for the replication group |
| <a name="output_elasticache_reader_endpoint_address"></a> [elasticache\_reader\_endpoint\_address](#output\_elasticache\_reader\_endpoint\_address) | Address of the reader endpoint for the replication group |
| <a name="output_elasticache_replication_group_arn"></a> [elasticache\_replication\_group\_arn](#output\_elasticache\_replication\_group\_arn) | ARN of the ElastiCache Replication Group |
| <a name="output_elasticache_replication_group_id"></a> [elasticache\_replication\_group\_id](#output\_elasticache\_replication\_group\_id) | ID of the ElastiCache Replication Group |
| <a name="output_elasticache_security_group_id"></a> [elasticache\_security\_group\_id](#output\_elasticache\_security\_group\_id) | ID of the security group created for ElastiCache |
| <a name="output_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#output\_elasticache\_subnet\_group\_name) | Name of the ElastiCache subnet group |
| <a name="output_inline_policies_enabled"></a> [inline\_policies\_enabled](#output\_inline\_policies\_enabled) | Whether inline policies feature is enabled |
| <a name="output_lb_security_group_arn"></a> [lb\_security\_group\_arn](#output\_lb\_security\_group\_arn) | ARN of the load balancer security group |
| <a name="output_lb_security_group_enabled"></a> [lb\_security\_group\_enabled](#output\_lb\_security\_group\_enabled) | Whether load balancer security group feature is enabled |
| <a name="output_lb_security_group_id"></a> [lb\_security\_group\_id](#output\_lb\_security\_group\_id) | ID of the load balancer security group |
| <a name="output_lb_security_group_name"></a> [lb\_security\_group\_name](#output\_lb\_security\_group\_name) | Name of the load balancer security group |
| <a name="output_oidc_enabled"></a> [oidc\_enabled](#output\_oidc\_enabled) | Whether OIDC/IRSA feature is enabled |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role for Rate Limiter application |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the IAM role for Rate Limiter application |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role for Rate Limiter application |
<!-- END_TF_DOCS -->