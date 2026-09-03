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
| <a name="module_chunks_bucket"></a> [chunks\_bucket](#module\_chunks\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_workload_identity"></a> [workload\_identity](#module\_workload\_identity) | terraform-google-modules/kubernetes-engine/google//modules/workload-identity | 44.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_pubsub_topic.bucket_notifications](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.gcs_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_storage_notification.chunks](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_notification) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_storage_project_service_account.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_project_roles"></a> [additional\_project\_roles](#input\_additional\_project\_roles) | Additional project-level IAM roles to grant Loki's service account | `list(string)` | `[]` | no |
| <a name="input_annotate_k8s_sa"></a> [annotate\_k8s\_sa](#input\_annotate\_k8s\_sa) | Whether to annotate the Kubernetes service account with the Google service account email. Only meaningful when use\_existing\_k8s\_sa = true; harmless otherwise | `bool` | `true` | no |
| <a name="input_bucket_force_destroy"></a> [bucket\_force\_destroy](#input\_bucket\_force\_destroy) | Whether to allow bucket deletion with objects in it | `bool` | `false` | no |
| <a name="input_bucket_lifecycle_rules"></a> [bucket\_lifecycle\_rules](#input\_bucket\_lifecycle\_rules) | Lifecycle rules for the chunks bucket, in the shape expected by simple\_bucket | `any` | `[]` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the chunks bucket | `string` | `"US"` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Custom chunks bucket name. If null, auto-generated as '<env>-<project>-loki-chunks' | `string` | `null` | no |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | GKE cluster CA certificate, base64-encoded - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | GKE cluster API server endpoint (bare host:port or IP, no scheme) - required to configure this module's kubernetes provider | `string` | n/a | yes |
| <a name="input_cluster_location"></a> [cluster\_location](#input\_cluster\_location) | Location (region or zone) of the GKE cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the GKE cluster hosting Loki | `string` | n/a | yes |
| <a name="input_enable_bucket_notifications"></a> [enable\_bucket\_notifications](#input\_enable\_bucket\_notifications) | Whether to create a Pub/Sub topic + notification for chunk bucket object-create events | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_k8s_namespace"></a> [k8s\_namespace](#input\_k8s\_namespace) | Kubernetes namespace Loki runs in | `string` | `"observability"` | no |
| <a name="input_k8s_service_account_name"></a> [k8s\_service\_account\_name](#input\_k8s\_service\_account\_name) | Kubernetes service account name used by Loki | `string` | `"loki"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |
| <a name="input_use_existing_k8s_sa"></a> [use\_existing\_k8s\_sa](#input\_use\_existing\_k8s\_sa) | Whether the Kubernetes service account already exists (typically created by this app's own Helm chart). Set true to bind Workload Identity to it instead of having Terraform create it - creating an SA the chart also owns collides on apply | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_notification_topic"></a> [bucket\_notification\_topic](#output\_bucket\_notification\_topic) | Name of the Pub/Sub topic receiving bucket notifications, if enabled |
| <a name="output_chunks_bucket_name"></a> [chunks\_bucket\_name](#output\_chunks\_bucket\_name) | Name of the chunks storage bucket |
| <a name="output_k8s_service_account_name"></a> [k8s\_service\_account\_name](#output\_k8s\_service\_account\_name) | Bound Kubernetes service account name |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of Loki's Google service account |
<!-- END_TF_DOCS -->
