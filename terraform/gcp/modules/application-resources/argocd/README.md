<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | ../gke-workload-identity | n/a |

## Resources

| Name | Type |
|------|------|
| [google_service_account_iam_member.cross_project_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant ArgoCD's service account | `list(string)` | `[]` | no |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | Kubernetes namespace where ArgoCD is deployed | `string` | `"argocd"` | no |
| <a name="input_argocd_service_accounts"></a> [argocd\_service\_accounts](#input\_argocd\_service\_accounts) | List of ArgoCD Kubernetes service accounts bound to Workload Identity. Only the first is bound directly (Workload Identity is 1:1 GSA<->KSA); grant the rest via kubectl annotation if they should share the same GSA | `list(string)` | <pre>[<br/>  "argocd-application-controller",<br/>  "argocd-applicationset-controller",<br/>  "argocd-server"<br/>]</pre> | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting ArgoCD | `string` | n/a | yes |
| <a name="input_cross_project_target_service_accounts"></a> [cross\_project\_target\_service\_accounts](#input\_cross\_project\_target\_service\_accounts) | List of fully qualified service account IDs (in other projects) that ArgoCD is allowed to impersonate for cross-project deployments | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to created resources that support them | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of ArgoCD's Google service account |
<!-- END_TF_DOCS -->
