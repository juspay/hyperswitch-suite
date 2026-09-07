<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bastion_host"></a> [bastion\_host](#module\_bastion\_host) | terraform-google-modules/bastion-host/google | 9.0.0 |
| <a name="module_session_log_bucket"></a> [session\_log\_bucket](#module\_session\_log\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_logging_project_sink.session_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | resource |
| [google_storage_bucket_iam_member.session_log_sink_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_service_account_roles"></a> [additional\_service\_account\_roles](#input\_additional\_service\_account\_roles) | Extra project-level IAM roles granted to the bastion's own service account, on top of the logging.logWriter/monitoring.metricWriter baseline this module always sets | `list(string)` | `[]` | no |
| <a name="input_connection_targets"></a> [connection\_targets](#input\_connection\_targets) | Data stores reachable by port-forwarding through this bastion, keyed by a short name. Drives the tunnel\_commands output only - it creates no resources and opens no firewall paths. | <pre>map(object({<br/>    host        = string<br/>    port        = number<br/>    local_port  = optional(number)<br/>    description = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Boot disk size in GB | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-balanced"` | no |
| <a name="input_enable_session_logging"></a> [enable\_session\_logging](#input\_enable\_session\_logging) | Whether to create a GCS bucket + log sink capturing bastion session/audit logs | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_image"></a> [image](#input\_image) | Specific image self-link to boot from. Null uses image\_family/image\_project instead | `string` | `null` | no |
| <a name="input_image_family"></a> [image\_family](#input\_image\_family) | Image family to boot from, used when image is null | `string` | `"debian-12"` | no |
| <a name="input_image_project"></a> [image\_project](#input\_image\_project) | Project the boot image/family belongs to | `string` | `"debian-cloud"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_log_bucket_location"></a> [log\_bucket\_location](#input\_log\_bucket\_location) | Location for the session log bucket | `string` | `"US"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for the bastion instance | `string` | `"e2-small"` | no |
| <a name="input_members"></a> [members](#input\_members) | List of IAM members (users/groups/service accounts) granted IAP-tunnel SSH access to the bastion | `list(string)` | `[]` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the bastion is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |
| <a name="input_session_log_retention_days"></a> [session\_log\_retention\_days](#input\_session\_log\_retention\_days) | Number of days to retain session log objects before deletion | `number` | `365` | no |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | Self-link of the subnetwork for the bastion (typically the management tier) | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone to create the bastion instance in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_connection_targets"></a> [connection\_targets](#output\_connection\_targets) | Resolved host/port of every data store reachable through this bastion, keyed by short name - the machine-readable counterpart of tunnel\_commands |
| <a name="output_instance_name"></a> [instance\_name](#output\_instance\_name) | Name of the bastion instance |
| <a name="output_instance_self_link"></a> [instance\_self\_link](#output\_instance\_self\_link) | Self-link of the bastion instance |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the bastion's service account |
| <a name="output_session_log_bucket_name"></a> [session\_log\_bucket\_name](#output\_session\_log\_bucket\_name) | Name of the session log bucket, if enabled |
| <a name="output_tunnel_commands"></a> [tunnel\_commands](#output\_tunnel\_commands) | Ready-to-run `gcloud compute ssh --tunnel-through-iap` local-port-forward command for each connection\_targets entry |
<!-- END_TF_DOCS -->
