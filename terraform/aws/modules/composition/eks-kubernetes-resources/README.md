<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler_irsa"></a> [cluster\_autoscaler\_irsa](#module\_cluster\_autoscaler\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.44.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [helm_release.hyperswitch_stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cluster_role_binding_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.cicd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.custom_roles](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.developer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.readonly](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_deployment_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1) | resource |
| [kubernetes_namespace_v1.hyperswitch](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_role_binding_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding_v1) | resource |
| [kubernetes_role_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_v1) | resource |
| [kubernetes_secret_v1.ecr_registry](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_account_v1.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [kubernetes_storage_class_v1.custom](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [kubernetes_storage_class_v1.ebs_gp3](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [terraform_data.cluster_ready](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.sync_cluster_autoscaler_image](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_ecr_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_authorization_token) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_autoscaler_architectures"></a> [cluster\_autoscaler\_architectures](#input\_cluster\_autoscaler\_architectures) | List of CPU architectures for multi-arch image sync (e.g., ['amd64', 'arm64']) | `list(string)` | <pre>[<br/>  "amd64",<br/>  "arm64"<br/>]</pre> | no |
| <a name="input_cluster_autoscaler_cluster_version"></a> [cluster\_autoscaler\_cluster\_version](#input\_cluster\_autoscaler\_cluster\_version) | Kubernetes cluster version (used to determine autoscaler version if image\_version not specified) | `string` | `null` | no |
| <a name="input_cluster_autoscaler_command"></a> [cluster\_autoscaler\_command](#input\_cluster\_autoscaler\_command) | Full command override for cluster autoscaler (replaces default command if provided) | `list(string)` | `null` | no |
| <a name="input_cluster_autoscaler_command_extra_args"></a> [cluster\_autoscaler\_command\_extra\_args](#input\_cluster\_autoscaler\_command\_extra\_args) | Additional command line arguments appended to default command | `list(string)` | `[]` | no |
| <a name="input_cluster_autoscaler_ecr_max_images"></a> [cluster\_autoscaler\_ecr\_max\_images](#input\_cluster\_autoscaler\_ecr\_max\_images) | Maximum number of images to keep in ECR lifecycle policy | `number` | `5` | no |
| <a name="input_cluster_autoscaler_ecr_repo_name"></a> [cluster\_autoscaler\_ecr\_repo\_name](#input\_cluster\_autoscaler\_ecr\_repo\_name) | Custom ECR repository name for cluster autoscaler (auto-generated if null) | `string` | `null` | no |
| <a name="input_cluster_autoscaler_ecr_repository_url"></a> [cluster\_autoscaler\_ecr\_repository\_url](#input\_cluster\_autoscaler\_ecr\_repository\_url) | Existing ECR repository URL for cluster autoscaler (skips ECR creation if provided) | `string` | `null` | no |
| <a name="input_cluster_autoscaler_enable_image_sync"></a> [cluster\_autoscaler\_enable\_image\_sync](#input\_cluster\_autoscaler\_enable\_image\_sync) | Whether to enable automatic image sync from public registry to ECR. Only applies when use\_ecr=true and ecr\_repository\_url is not provided. | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_expander"></a> [cluster\_autoscaler\_expander](#input\_cluster\_autoscaler\_expander) | Expander strategy for cluster autoscaler (least-waste, most-pods, priority, random) | `string` | `"least-waste"` | no |
| <a name="input_cluster_autoscaler_extra_args"></a> [cluster\_autoscaler\_extra\_args](#input\_cluster\_autoscaler\_extra\_args) | Additional command line arguments for cluster autoscaler | `list(string)` | `[]` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Full image URL for cluster autoscaler (ECR or public) | `string` | `null` | no |
| <a name="input_cluster_autoscaler_image_version"></a> [cluster\_autoscaler\_image\_version](#input\_cluster\_autoscaler\_image\_version) | Cluster Autoscaler image version tag (e.g., 'v1.35.0'). Auto-detected from cluster version if null | `string` | `null` | no |
| <a name="input_cluster_autoscaler_log_level"></a> [cluster\_autoscaler\_log\_level](#input\_cluster\_autoscaler\_log\_level) | Log level for cluster autoscaler (1-5) | `number` | `4` | no |
| <a name="input_cluster_autoscaler_node_selector"></a> [cluster\_autoscaler\_node\_selector](#input\_cluster\_autoscaler\_node\_selector) | Node selector for scheduling cluster autoscaler pod | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler_pod_annotations"></a> [cluster\_autoscaler\_pod\_annotations](#input\_cluster\_autoscaler\_pod\_annotations) | Additional pod annotations for cluster autoscaler | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler_resources"></a> [cluster\_autoscaler\_resources](#input\_cluster\_autoscaler\_resources) | Resource requests and limits for cluster autoscaler | <pre>object({<br/>    requests_cpu    = optional(string, "100m")<br/>    requests_memory = optional(string, "600Mi")<br/>    limits_cpu      = optional(string, "100m")<br/>    limits_memory   = optional(string, "600Mi")<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_autoscaler_service_account_name"></a> [cluster\_autoscaler\_service\_account\_name](#input\_cluster\_autoscaler\_service\_account\_name) | Service account name for cluster autoscaler | `string` | `null` | no |
| <a name="input_cluster_autoscaler_skip_local_storage"></a> [cluster\_autoscaler\_skip\_local\_storage](#input\_cluster\_autoscaler\_skip\_local\_storage) | Skip nodes with local storage | `bool` | `false` | no |
| <a name="input_cluster_autoscaler_skip_system_pods"></a> [cluster\_autoscaler\_skip\_system\_pods](#input\_cluster\_autoscaler\_skip\_system\_pods) | Skip nodes with system pods | `bool` | `false` | no |
| <a name="input_cluster_autoscaler_source_registry"></a> [cluster\_autoscaler\_source\_registry](#input\_cluster\_autoscaler\_source\_registry) | Container registry for cluster autoscaler image source | `string` | `"registry.k8s.io"` | no |
| <a name="input_cluster_autoscaler_tolerations"></a> [cluster\_autoscaler\_tolerations](#input\_cluster\_autoscaler\_tolerations) | Tolerations for scheduling cluster autoscaler pod | <pre>list(object({<br/>    key      = string<br/>    operator = string<br/>    value    = optional(string)<br/>    effect   = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_autoscaler_use_ecr"></a> [cluster\_autoscaler\_use\_ecr](#input\_cluster\_autoscaler\_use\_ecr) | Whether to use ECR for cluster autoscaler image. Set to false to use public registry directly. | `bool` | `false` | no |
| <a name="input_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#input\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint for the Kubernetes API server | `string` | n/a | yes |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_create_default_rbac_roles"></a> [create\_default\_rbac\_roles](#input\_create\_default\_rbac\_roles) | Whether to create default RBAC roles (developer, readonly, cicd) | `bool` | `true` | no |
| <a name="input_create_default_storage_class"></a> [create\_default\_storage\_class](#input\_create\_default\_storage\_class) | Whether to create default gp3 storage class for EBS volumes | `bool` | `true` | no |
| <a name="input_create_ecr_registry_secret"></a> [create\_ecr\_registry\_secret](#input\_create\_ecr\_registry\_secret) | Whether to create ECR registry secret for pulling images | `bool` | `true` | no |
| <a name="input_custom_rbac_roles"></a> [custom\_rbac\_roles](#input\_custom\_rbac\_roles) | Additional custom RBAC roles to create | <pre>map(object({<br/>    rules = list(object({<br/>      api_groups     = list(string)<br/>      resources      = list(string)<br/>      verbs          = list(string)<br/>      resource_names = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_storage_classes"></a> [custom\_storage\_classes](#input\_custom\_storage\_classes) | Map of additional custom storage classes to create | <pre>map(object({<br/>    storage_provisioner    = string<br/>    volume_binding_mode    = optional(string, "Immediate")<br/>    reclaim_policy         = optional(string, "Retain")<br/>    allow_volume_expansion = optional(bool, false)<br/>    parameters             = optional(map(string), {})<br/>    annotations            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_default_storage_class_name"></a> [default\_storage\_class\_name](#input\_default\_storage\_class\_name) | Name of the default storage class | `string` | `"ebs-gp3"` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable\_cluster\_autoscaler](#input\_enable\_cluster\_autoscaler) | Whether to deploy Cluster Autoscaler Kubernetes resources | `bool` | `false` | no |
| <a name="input_enable_helm_deployments"></a> [enable\_helm\_deployments](#input\_enable\_helm\_deployments) | Enable Helm deployments managed by Terraform. Set to false if using ArgoCD from another cluster | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_hyperswitch_chart_version"></a> [hyperswitch\_chart\_version](#input\_hyperswitch\_chart\_version) | Helm chart version for Hyperswitch (null for latest) | `string` | `null` | no |
| <a name="input_hyperswitch_helm_chart"></a> [hyperswitch\_helm\_chart](#input\_hyperswitch\_helm\_chart) | Helm chart name for Hyperswitch | `string` | `"hyperswitch-stack"` | no |
| <a name="input_hyperswitch_helm_repository"></a> [hyperswitch\_helm\_repository](#input\_hyperswitch\_helm\_repository) | Helm repository URL for Hyperswitch chart | `string` | `"https://juspay.github.io/hyperswitch-helm"` | no |
| <a name="input_hyperswitch_helm_timeout"></a> [hyperswitch\_helm\_timeout](#input\_hyperswitch\_helm\_timeout) | Timeout in seconds for Helm deployment | `number` | `900` | no |
| <a name="input_hyperswitch_namespace"></a> [hyperswitch\_namespace](#input\_hyperswitch\_namespace) | Kubernetes namespace for Hyperswitch deployment | `string` | `"hyperswitch"` | no |
| <a name="input_hyperswitch_release_name"></a> [hyperswitch\_release\_name](#input\_hyperswitch\_release\_name) | Helm release name for Hyperswitch stack | `string` | `"hyperswitch-stack"` | no |
| <a name="input_hyperswitch_values_file"></a> [hyperswitch\_values\_file](#input\_hyperswitch\_values\_file) | Path to custom Helm values file for Hyperswitch (null for defaults) | `string` | `null` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | The ARN of the OIDC Provider from the EKS cluster (for IRSA) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for ECR operations | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_autoscaler_deployment_name"></a> [cluster\_autoscaler\_deployment\_name](#output\_cluster\_autoscaler\_deployment\_name) | Deployment name for cluster autoscaler |
| <a name="output_cluster_autoscaler_ecr_repository_arn"></a> [cluster\_autoscaler\_ecr\_repository\_arn](#output\_cluster\_autoscaler\_ecr\_repository\_arn) | ECR repository ARN for cluster autoscaler image (if created) |
| <a name="output_cluster_autoscaler_ecr_repository_url"></a> [cluster\_autoscaler\_ecr\_repository\_url](#output\_cluster\_autoscaler\_ecr\_repository\_url) | ECR repository URL for cluster autoscaler image (if created) |
| <a name="output_cluster_autoscaler_iam_role_arn"></a> [cluster\_autoscaler\_iam\_role\_arn](#output\_cluster\_autoscaler\_iam\_role\_arn) | IAM role ARN for Cluster Autoscaler IRSA |
| <a name="output_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#output\_cluster\_autoscaler\_image) | Full image URL for cluster autoscaler (ECR or public) |
| <a name="output_cluster_autoscaler_service_account"></a> [cluster\_autoscaler\_service\_account](#output\_cluster\_autoscaler\_service\_account) | Service account name for cluster autoscaler |
| <a name="output_custom_storage_class_names"></a> [custom\_storage\_class\_names](#output\_custom\_storage\_class\_names) | Names of the custom storage classes created |
| <a name="output_default_storage_class_name"></a> [default\_storage\_class\_name](#output\_default\_storage\_class\_name) | Name of the default storage class (if created) |
| <a name="output_ecr_registry_secret_name"></a> [ecr\_registry\_secret\_name](#output\_ecr\_registry\_secret\_name) | Name of the ECR registry secret (if created) |
| <a name="output_hyperswitch_helm_release_status"></a> [hyperswitch\_helm\_release\_status](#output\_hyperswitch\_helm\_release\_status) | Status of the Hyperswitch Helm release (if deployed) |
| <a name="output_hyperswitch_namespace"></a> [hyperswitch\_namespace](#output\_hyperswitch\_namespace) | Name of the Hyperswitch namespace (if created) |
| <a name="output_rbac_roles_created"></a> [rbac\_roles\_created](#output\_rbac\_roles\_created) | List of RBAC roles created |
<!-- END_TF_DOCS -->