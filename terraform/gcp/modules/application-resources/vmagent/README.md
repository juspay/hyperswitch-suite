<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use\_existing\_k8s\_sa = true; Helm sets the annotation, so this defaults to false | `bool` | `false` | no |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting vmagent | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace vmagent runs in | `string` | `"monitoring"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by vmagent (the VictoriaMetrics operator names it vmagent-<fullnameOverride>) | `string` | `"vmagent-victoria-metrics"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |
| <a name="input_project_roles"></a> [project\_roles](#input\_project\_roles) | Project-level IAM roles granted to vmagent's service account | `list(string)` | <pre>[<br/>  "roles/compute.viewer"<br/>]</pre> | no |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account is created elsewhere (the monitoring Helm release). Defaults to true so Terraform only creates the GCP-side identity and binding | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of vmagent's Google service account - use as the iam.gke.io/gcp-service-account annotation on the vmagent Kubernetes service account |
<!-- END_TF_DOCS -->
