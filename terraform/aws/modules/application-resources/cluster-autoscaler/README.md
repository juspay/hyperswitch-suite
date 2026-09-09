<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | Additional IAM policy ARNs to attach to the role | `list(string)` | `[]` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster the Cluster Autoscaler scales | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, integ, prod) | `string` | n/a | yes |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration (in seconds) for the IAM role | `number` | `3600` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace the Cluster Autoscaler is deployed into | `string` | `"kube-system"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of the IAM role | `string` | `"IAM role for the Cluster Autoscaler (IRSA)"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the IAM role. Defaults to <environment>-<project\_name>-cluster-autoscaler when null. | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path for the IAM role and policy | `string` | `"/"` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Name of the Cluster Autoscaler service account the IAM role is scoped to. Must match the service account created by the Helm chart deployed via ArgoCD. | `string` | `"cluster-autoscaler"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace the Cluster Autoscaler is deployed into |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | ARN of the Cluster Autoscaler IAM policy |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the Cluster Autoscaler IAM role, consumed by the Helm chart service account annotation |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the Cluster Autoscaler IAM role |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Name of the service account the IAM role is scoped to |
<!-- END_TF_DOCS -->
