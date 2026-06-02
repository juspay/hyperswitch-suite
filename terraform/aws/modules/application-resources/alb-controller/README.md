<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_load_balancer_controller_irsa"></a> [aws\_load\_balancer\_controller\_irsa](#module\_aws\_load\_balancer\_controller\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [helm_release.alb_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account_v1.alb_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_service_account_annotations"></a> [additional\_service\_account\_annotations](#input\_additional\_service\_account\_annotations) | Additional annotations to apply to the ALB Controller Service Account | `map(string)` | `{}` | no |
| <a name="input_alb_controller_chart_version"></a> [alb\_controller\_chart\_version](#input\_alb\_controller\_chart\_version) | Version of the AWS Load Balancer Controller Helm chart | `string` | `"1.14.0"` | no |
| <a name="input_alb_controller_namespace"></a> [alb\_controller\_namespace](#input\_alb\_controller\_namespace) | Namespace ALB Controller is installed on | `string` | `"kube-system"` | no |
| <a name="input_alb_controller_service_account_name"></a> [alb\_controller\_service\_account\_name](#input\_alb\_controller\_service\_account\_name) | Service Account Name of ALB Controller | `string` | `"aws-load-balancer-controller-sa"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_alb_controller_service_account"></a> [create\_alb\_controller\_service\_account](#input\_create\_alb\_controller\_service\_account) | Whether to create the ALB Controller Service Account | `bool` | `false` | no |
| <a name="input_create_helm_release"></a> [create\_helm\_release](#input\_create\_helm\_release) | Whether to create the Helm release for ALB Controller | `bool` | `true` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_helm_chart_repository"></a> [helm\_chart\_repository](#input\_helm\_chart\_repository) | Helm chart repository URL | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_helm_chart_values"></a> [helm\_chart\_values](#input\_helm\_chart\_values) | Additional values to pass to the Helm chart | `list(string)` | `[]` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | Name of the Helm release | `string` | `"aws-load-balancer-controller"` | no |
| <a name="input_helm_values_file"></a> [helm\_values\_file](#input\_helm\_values\_file) | Path to a values.yaml file to use with the Helm chart. If provided, this will be used alongside helm\_chart\_values | `string` | `""` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_service_account_labels"></a> [service\_account\_labels](#input\_service\_account\_labels) | Labels to apply to the ALB Controller Service Account | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_controller_role_arn"></a> [alb\_controller\_role\_arn](#output\_alb\_controller\_role\_arn) | The ARN of the AWS Load Balancer Controller IAM role |
| <a name="output_alb_controller_service_account"></a> [alb\_controller\_service\_account](#output\_alb\_controller\_service\_account) | Service Account Name of AWS Load Balancer Controller |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
<!-- END_TF_DOCS -->