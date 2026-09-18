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
| <a name="module_external_dns_irsa"></a> [external\_dns\_irsa](#module\_external\_dns\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [helm_release.external_dns](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account_v1.external_dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_openid_connect_provider.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_service_account_annotations"></a> [additional\_service\_account\_annotations](#input\_additional\_service\_account\_annotations) | Additional annotations to apply to the external-dns Service Account | `map(string)` | `{}` | no |
| <a name="input_aws_zone_type"></a> [aws\_zone\_type](#input\_aws\_zone\_type) | Which zone type external-dns should manage records in (public, private, or empty for both) | `string` | `"public"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_external_dns_service_account"></a> [create\_external\_dns\_service\_account](#input\_create\_external\_dns\_service\_account) | Whether to create the external-dns Service Account | `bool` | `false` | no |
| <a name="input_create_helm_release"></a> [create\_helm\_release](#input\_create\_helm\_release) | Whether to create the Helm release for external-dns | `bool` | `true` | no |
| <a name="input_domain_filters"></a> [domain\_filters](#input\_domain\_filters) | List of domains external-dns is allowed to manage records for (--domain-filter) | `list(string)` | `[]` | no |
| <a name="input_dry_run"></a> [dry\_run](#input\_dry\_run) | Run external-dns in --dry-run mode (log intended changes, write nothing to Route53) | `bool` | `true` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_external_dns_chart_version"></a> [external\_dns\_chart\_version](#input\_external\_dns\_chart\_version) | Version of the external-dns Helm chart | `string` | `"1.15.0"` | no |
| <a name="input_external_dns_hosted_zone_arns"></a> [external\_dns\_hosted\_zone\_arns](#input\_external\_dns\_hosted\_zone\_arns) | List of Route53 hosted zone ARNs external-dns is allowed to manage records in | `list(string)` | n/a | yes |
| <a name="input_external_dns_namespace"></a> [external\_dns\_namespace](#input\_external\_dns\_namespace) | Namespace external-dns is installed on | `string` | `"kube-system"` | no |
| <a name="input_external_dns_service_account_name"></a> [external\_dns\_service\_account\_name](#input\_external\_dns\_service\_account\_name) | Service Account Name of external-dns | `string` | `"external-dns-sa"` | no |
| <a name="input_helm_chart_repository"></a> [helm\_chart\_repository](#input\_helm\_chart\_repository) | Helm chart repository URL | `string` | `"https://kubernetes-sigs.github.io/external-dns"` | no |
| <a name="input_helm_chart_values"></a> [helm\_chart\_values](#input\_helm\_chart\_values) | Additional values to pass to the Helm chart | `list(string)` | `[]` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | Name of the Helm release | `string` | `"external-dns"` | no |
| <a name="input_helm_values_file"></a> [helm\_values\_file](#input\_helm\_values\_file) | Path to a values.yaml file to use with the Helm chart. If provided, this will be used alongside helm\_chart\_values | `string` | `""` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | external-dns record ownership policy: sync (create/update/delete) or upsert-only (never delete) | `string` | `"upsert-only"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_service_account_labels"></a> [service\_account\_labels](#input\_service\_account\_labels) | Labels to apply to the external-dns Service Account | `map(string)` | `{}` | no |
| <a name="input_txt_owner_id"></a> [txt\_owner\_id](#input\_txt\_owner\_id) | TXT registry owner ID used by external-dns to disambiguate records it owns (--txt-owner-id). Must be unique per cluster/region sharing a zone. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_zone_type"></a> [aws\_zone\_type](#output\_aws\_zone\_type) | Zone type external-dns is scoped to (public, private, or empty for both), as passed to var.aws\_zone\_type |
| <a name="output_domain_filters"></a> [domain\_filters](#output\_domain\_filters) | Domains external-dns is allowed to manage records for, as passed to var.domain\_filters |
| <a name="output_external_dns_role_arn"></a> [external\_dns\_role\_arn](#output\_external\_dns\_role\_arn) | The ARN of the external-dns IAM role |
| <a name="output_external_dns_service_account"></a> [external\_dns\_service\_account](#output\_external\_dns\_service\_account) | Service Account Name of external-dns |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
<!-- END_TF_DOCS -->
