<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.hyperswitch_stack](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cluster_role_v1.cicd](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.custom_roles](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.developer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_cluster_role_v1.readonly](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_namespace_v1.hyperswitch](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.registry_pull_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_storage_class_v1.custom](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [kubernetes_storage_class_v1.pd_balanced](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [terraform_data.cluster_ready](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | Base64 encoded certificate data required to communicate with the cluster | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint (host, without scheme) for the Kubernetes API server | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster | `string` | n/a | yes |
| <a name="input_create_default_rbac_roles"></a> [create\_default\_rbac\_roles](#input\_create\_default\_rbac\_roles) | Whether to create default RBAC roles (developer, readonly, cicd) | `bool` | `true` | no |
| <a name="input_create_default_storage_class"></a> [create\_default\_storage\_class](#input\_create\_default\_storage\_class) | Whether to create the default pd-balanced storage class | `bool` | `true` | no |
| <a name="input_create_registry_pull_secret"></a> [create\_registry\_pull\_secret](#input\_create\_registry\_pull\_secret) | Whether to create a docker registry pull secret. Not normally needed for Artifact Registry, which authenticates via Workload Identity | `bool` | `false` | no |
| <a name="input_custom_rbac_roles"></a> [custom\_rbac\_roles](#input\_custom\_rbac\_roles) | Additional custom RBAC roles to create | <pre>map(object({<br/>    rules = list(object({<br/>      api_groups     = list(string)<br/>      resources      = list(string)<br/>      verbs          = list(string)<br/>      resource_names = optional(list(string), [])<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_storage_classes"></a> [custom\_storage\_classes](#input\_custom\_storage\_classes) | Map of additional custom storage classes to create | <pre>map(object({<br/>    storage_provisioner    = string<br/>    volume_binding_mode    = optional(string, "Immediate")<br/>    reclaim_policy         = optional(string, "Retain")<br/>    allow_volume_expansion = optional(bool, false)<br/>    parameters             = optional(map(string), {})<br/>    annotations            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_default_storage_class_name"></a> [default\_storage\_class\_name](#input\_default\_storage\_class\_name) | Name of the default storage class | `string` | `"pd-balanced"` | no |
| <a name="input_enable_helm_deployments"></a> [enable\_helm\_deployments](#input\_enable\_helm\_deployments) | Enable Helm deployments managed by Terraform. Set to false if using ArgoCD instead | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_hyperswitch_chart_version"></a> [hyperswitch\_chart\_version](#input\_hyperswitch\_chart\_version) | Helm chart version for Hyperswitch (null for latest) | `string` | `null` | no |
| <a name="input_hyperswitch_helm_chart"></a> [hyperswitch\_helm\_chart](#input\_hyperswitch\_helm\_chart) | Helm chart name for Hyperswitch | `string` | `"hyperswitch-stack"` | no |
| <a name="input_hyperswitch_helm_repository"></a> [hyperswitch\_helm\_repository](#input\_hyperswitch\_helm\_repository) | Helm repository URL for Hyperswitch chart | `string` | `"https://juspay.github.io/hyperswitch-helm"` | no |
| <a name="input_hyperswitch_helm_timeout"></a> [hyperswitch\_helm\_timeout](#input\_hyperswitch\_helm\_timeout) | Timeout in seconds for Helm deployment | `number` | `900` | no |
| <a name="input_hyperswitch_namespace"></a> [hyperswitch\_namespace](#input\_hyperswitch\_namespace) | Kubernetes namespace for Hyperswitch deployment | `string` | `"hyperswitch"` | no |
| <a name="input_hyperswitch_release_name"></a> [hyperswitch\_release\_name](#input\_hyperswitch\_release\_name) | Helm release name for Hyperswitch stack | `string` | `"hyperswitch-stack"` | no |
| <a name="input_hyperswitch_values_file"></a> [hyperswitch\_values\_file](#input\_hyperswitch\_values\_file) | Path to custom Helm values file for Hyperswitch (null for defaults) | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_registry_pull_secret_password"></a> [registry\_pull\_secret\_password](#input\_registry\_pull\_secret\_password) | Password/token for the optional pull secret | `string` | `null` | no |
| <a name="input_registry_pull_secret_server"></a> [registry\_pull\_secret\_server](#input\_registry\_pull\_secret\_server) | Registry server for the optional pull secret | `string` | `null` | no |
| <a name="input_registry_pull_secret_username"></a> [registry\_pull\_secret\_username](#input\_registry\_pull\_secret\_username) | Username for the optional pull secret | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_default_storage_class_name"></a> [default\_storage\_class\_name](#output\_default\_storage\_class\_name) | Name of the default storage class, if created |
| <a name="output_hyperswitch_namespace"></a> [hyperswitch\_namespace](#output\_hyperswitch\_namespace) | Namespace the Hyperswitch Helm release was deployed into, if enabled |
| <a name="output_hyperswitch_release_status"></a> [hyperswitch\_release\_status](#output\_hyperswitch\_release\_status) | Status of the Hyperswitch Helm release, if enabled |
| <a name="output_rbac_role_names"></a> [rbac\_role\_names](#output\_rbac\_role\_names) | Names of created default RBAC cluster roles |
<!-- END_TF_DOCS -->
