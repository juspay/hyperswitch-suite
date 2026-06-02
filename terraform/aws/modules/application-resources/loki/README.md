<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.aws_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.customer_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.s3_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks_ingress_from_loki](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lb_egress_to_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM assume role policy statements to append | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name | `string` | `"loki"` | no |
| <a name="input_assume_role_principals"></a> [assume\_role\_principals](#input\_assume\_role\_principals) | List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root']) | `list(string)` | `[]` | no |
| <a name="input_aws_managed_policy_names"></a> [aws\_managed\_policy\_names](#input\_aws\_managed\_policy\_names) | List of AWS managed policy names to attach | `list(string)` | `[]` | no |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name) | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for the Loki ALB ingress | `bool` | `false` | no |
| <a name="input_customer_managed_policy_arns"></a> [customer\_managed\_policy\_arns](#input\_customer\_managed\_policy\_arns) | List of customer managed policy ARNs to attach | `list(string)` | `[]` | no |
| <a name="input_eks_node_security_group_id"></a> [eks\_node\_security\_group\_id](#input\_eks\_node\_security\_group\_id) | EKS node security group ID. When provided, the module will create ingress rules on the EKS node security group to allow traffic from the Loki LB, and egress rules on the Loki LB to reach EKS nodes. | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_force_detach_policies"></a> [force\_detach\_policies](#input\_force\_detach\_policies) | Whether to force detaching policies when destroying the role | `bool` | `true` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the role (in seconds) | `number` | `3600` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `null` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Custom IAM role description | `string` | `null` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | IAM role path | `string` | `"/"` | no |
| <a name="input_s3"></a> [s3](#input\_s3) | S3 bucket configuration for Loki logs storage. Set to {} to disable. Set create=true to create bucket, or create=false with bucket\_arn to use existing. | <pre>object({<br/>    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing<br/>    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)<br/><br/>    # Bucket creation settings (used when create=true)<br/>    bucket_name        = optional(string, null) # Auto-generated if not provided<br/>    force_destroy      = optional(bool, false)<br/>    versioning_enabled = optional(bool, false)<br/>    lifecycle_rules    = optional(any, [])<br/>  })</pre> | `{}` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description for the security group | `string` | `"Security group for Loki ALB ingress"` | no |
| <a name="input_security_group_egress_rules"></a> [security\_group\_egress\_rules](#input\_security\_group\_egress\_rules) | List of egress rules for the security group | <pre>list(object({<br/>    description              = string<br/>    from_port                = number<br/>    to_port                  = number<br/>    protocol                 = string<br/>    cidr_blocks              = optional(list(string), null)<br/>    source_security_group_id = optional(string, null)<br/>    prefix_list_ids          = optional(list(string), null)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "cidr_blocks": [<br/>      "0.0.0.0/0"<br/>    ],<br/>    "description": "Allow all outbound traffic",<br/>    "from_port": 0,<br/>    "protocol": "-1",<br/>    "to_port": 0<br/>  }<br/>]</pre> | no |
| <a name="input_security_group_ingress_rules"></a> [security\_group\_ingress\_rules](#input\_security\_group\_ingress\_rules) | List of ingress rules for the security group | <pre>list(object({<br/>    description              = string<br/>    from_port                = number<br/>    to_port                  = number<br/>    protocol                 = string<br/>    cidr_blocks              = optional(list(string), null)<br/>    source_security_group_id = optional(string, null)<br/>    prefix_list_ids          = optional(list(string), null)<br/>  }))</pre> | `[]` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Custom name for the security group. If null, auto-generated as {environment}-{project}-{app}-alb-sg | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the security group will be created. Required if create\_security\_group is true. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account ID |
| <a name="output_assume_role_principals_enabled"></a> [assume\_role\_principals\_enabled](#output\_assume\_role\_principals\_enabled) | Whether assume role principals feature is enabled |
| <a name="output_aws_managed_policies_enabled"></a> [aws\_managed\_policies\_enabled](#output\_aws\_managed\_policies\_enabled) | Whether AWS managed policy attachments feature is enabled |
| <a name="output_customer_managed_policies_enabled"></a> [customer\_managed\_policies\_enabled](#output\_customer\_managed\_policies\_enabled) | Whether customer managed policy attachments feature is enabled |
| <a name="output_oidc_enabled"></a> [oidc\_enabled](#output\_oidc\_enabled) | Whether OIDC/IRSA feature is enabled |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role for Loki application |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the IAM role for Loki application |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role for Loki application |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of the S3 bucket (null if not enabled) |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | Domain name of the S3 bucket (null if not created) |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket (null if not created) |
| <a name="output_s3_bucket_region"></a> [s3\_bucket\_region](#output\_s3\_bucket\_region) | AWS region of the S3 bucket (null if not created) |
| <a name="output_s3_bucket_regional_domain_name"></a> [s3\_bucket\_regional\_domain\_name](#output\_s3\_bucket\_regional\_domain\_name) | Regional domain name of the S3 bucket (null if not created) |
| <a name="output_s3_enabled"></a> [s3\_enabled](#output\_s3\_enabled) | Whether S3 bucket feature is enabled |
| <a name="output_s3_policy_arn"></a> [s3\_policy\_arn](#output\_s3\_policy\_arn) | ARN of the S3 IAM policy (if enabled) |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group (null if not created) |
| <a name="output_security_group_enabled"></a> [security\_group\_enabled](#output\_security\_group\_enabled) | Whether security group feature is enabled |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group (null if not created) |
| <a name="output_security_group_name"></a> [security\_group\_name](#output\_security\_group\_name) | Name of the security group (null if not created) |
<!-- END_TF_DOCS -->