<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.argocd_management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.cross_account_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.cross_account_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM policy statements to add to the role's assume role policy | `list(any)` | `[]` | no |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | Additional policy ARNs to attach to the ArgoCD role | `list(string)` | `[]` | no |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | Kubernetes namespace where ArgoCD is deployed | `string` | `"argocd"` | no |
| <a name="input_argocd_service_accounts"></a> [argocd\_service\_accounts](#input\_argocd\_service\_accounts) | List of ArgoCD service accounts that can assume this role | `list(string)` | <pre>[<br/>  "argocd-application-controller",<br/>  "argocd-applicationset-controller",<br/>  "argocd-server"<br/>]</pre> | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID where the role is created | `string` | n/a | yes |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of cluster names to service accounts that can assume this role. Each service account must have 'namespace' and 'name' attributes. | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_assume_role_policy"></a> [create\_assume\_role\_policy](#input\_create\_assume\_role\_policy) | Whether to create and attach the assume role policy for cross-account access | `bool` | `true` | no |
| <a name="input_cross_account_roles"></a> [cross\_account\_roles](#input\_cross\_account\_roles) | List of cross-account role ARNs that ArgoCD can assume | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds for the role | `number` | `3600` | no |
| <a name="input_oidc_audience"></a> [oidc\_audience](#input\_oidc\_audience) | Audience for OIDC token validation | `string` | `"sts.amazonaws.com"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description for the ArgoCD management IAM role | `string` | `"IAM role for ArgoCD to manage cross-account deployments"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the ArgoCD management IAM role. If null, defaults to {project}-{env}-argocd-management-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path for the IAM role | `string` | `"/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_service_accounts"></a> [cluster\_service\_accounts](#output\_cluster\_service\_accounts) | Map of cluster names to their service account subjects |
| <a name="output_oidc_provider_urls"></a> [oidc\_provider\_urls](#output\_oidc\_provider\_urls) | Map of cluster names to their OIDC provider URLs |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the ArgoCD management IAM role |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the ArgoCD management IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the ArgoCD management IAM role |
| <a name="output_role_unique_id"></a> [role\_unique\_id](#output\_role\_unique\_id) | Unique ID of the ArgoCD management IAM role |
<!-- END_TF_DOCS -->