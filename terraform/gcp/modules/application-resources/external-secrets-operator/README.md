<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 7.46.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_secret_manager_secret_iam_member.accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant the operator's service account (e.g. roles/secretmanager.viewer for the PushSecret/discovery paths) | `list(string)` | `[]` | no |
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use\_existing\_k8s\_sa = true; harmless otherwise | `bool` | `true` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting the operator | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace the operator runs in | `string` | `"external-secrets-operator"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by the operator | `string` | `"external-secrets-sa"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_scope_to_project"></a> [scope\_to\_project](#input\_scope\_to\_project) | Whether to grant project-wide roles/secretmanager.secretAccessor. True is<br/>the closest equivalent of the AWS module, whose inline policy always<br/>covers every secret in the account/region.<br/><br/>Set false and populate secret\_ids for least privilege. Setting false with<br/>an empty secret\_ids grants the operator no Secret Manager access at all -<br/>it will start cleanly and then fail every ExternalSecret it reconciles<br/>with a permission error, which is not an obvious symptom. | `bool` | `true` | no |
| <a name="input_secret_ids"></a> [secret\_ids](#input\_secret\_ids) | Secret Manager secret IDs to grant per-secret accessor access to, in addition to (or instead of) the project-wide role | `list(string)` | `[]` | no |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account already exists (typically created by the operator's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_granted_project_roles"></a> [granted\_project\_roles](#output\_granted\_project\_roles) | Project-level IAM roles actually granted to the operator's service account |
| <a name="output_granted_secret_ids"></a> [granted\_secret\_ids](#output\_granted\_secret\_ids) | Secret Manager secret IDs granted per-secret accessor access |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_k8s_service_account_namespace"></a> [k8s\_service\_account\_namespace](#output\_k8s\_service\_account\_namespace) | Namespace of the bound Kubernetes service account |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the operator's Google service account - the value a SecretStore's workloadIdentity/serviceAccountRef ultimately resolves to |
| <a name="output_service_account_name"></a> [service\_account\_name](#output\_service\_account\_name) | Fully qualified name of the operator's Google service account |
<!-- END_TF_DOCS -->
