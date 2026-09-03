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
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_internal_lb"></a> [internal\_lb](#module\_internal\_lb) | terraform-google-modules/lb-internal/google | 7.1.0 |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_proxy_mig"></a> [proxy\_mig](#module\_proxy\_mig) | terraform-google-modules/vm/google//modules/mig | 15.2.1 |
| <a name="module_proxy_template"></a> [proxy\_template](#module\_proxy\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_storage_bucket_object.additional_config_files](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.squid_allowlist](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.squid_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.vector_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_config_files_path"></a> [additional\_config\_files\_path](#input\_additional\_config\_files\_path) | Optional local directory whose files are uploaded verbatim to the config bucket. No placeholder templating is applied. "squid.conf", "allowedlist.txt" and "vector.toml" are skipped, since the dedicated *\_content variables already own those objects. Null skips this entirely | `string` | `null` | no |
| <a name="input_autoscaling_cpu_target"></a> [autoscaling\_cpu\_target](#input\_autoscaling\_cpu\_target) | Target CPU utilization (0-1) for the autoscaler | `number` | `0.6` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the config/log buckets | `string` | `"US"` | no |
| <a name="input_custom_startup_script"></a> [custom\_startup\_script](#input\_custom\_startup\_script) | GCE startup-script content run on boot. Normally unnecessary: the Packer image already bakes in squid-config-fetch.service and squid-whitelist-fetch.service, which pull squid.conf/allowedlist.txt from the config bucket before Squid starts, plus a cron job that re-syncs the whitelist. Null (default) sets no startup-script. Only set this for boot-time behavior beyond what the image provides | `string` | `null` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Boot disk size in GB | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-balanced"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_force_destroy_buckets"></a> [force\_destroy\_buckets](#input\_force\_destroy\_buckets) | Whether the config/log buckets can be destroyed while non-empty - required for `terraform destroy` to succeed at all, since versioning leaves noncurrent object versions behind. Null (default) auto-derives: true everywhere except "prod" | `bool` | `null` | no |
| <a name="input_ilb_source_ranges"></a> [ilb\_source\_ranges](#input\_ilb\_source\_ranges) | CIDR ranges allowed to reach the internal LB's forwarding rule on squid\_port. Required, with no default: the underlying lb-internal module falls back to 0.0.0.0/0 when both source\_ip\_ranges and source\_tags are unset. Squid's clients are GKE pods, which carry no network tags to match on, so this must be IP-range based - keep it in sync with the gke-to-squid-egress rule in the same environment's firewall-rules unit | `list(string)` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_lb_subnetwork"></a> [lb\_subnetwork](#input\_lb\_subnetwork) | Self-link of the subnetwork for the internal load balancer's forwarding rule | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain access log objects before deletion | `number` | `90` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for proxy instances | `string` | `"n2-standard-2"` | no |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | Maximum number of proxy instances | `number` | `6` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata applied to proxy instances (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | Minimum number of proxy instances | `number` | `2` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_proxy_subnetwork"></a> [proxy\_subnetwork](#input\_proxy\_subnetwork) | Self-link of the subnetwork for Squid proxy instances (typically the outgoing-proxy tier) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |
| <a name="input_squid_allowlist_content"></a> [squid\_allowlist\_content](#input\_squid\_allowlist\_content) | Whitelisted-domains file content (allowedlist.txt), written to the config bucket and synced onto instances every 15 min by the image's whitelist-fetch cron job (squid -k reconfigure, no instance replacement needed). Null skips writing the object. | `string` | `null` | no |
| <a name="input_squid_config_content"></a> [squid\_config\_content](#input\_squid\_config\_content) | squid.conf content, written to the config bucket. Null skips writing a config object | `string` | `null` | no |
| <a name="input_squid_image"></a> [squid\_image](#input\_squid\_image) | Self-link or family of the custom image with Squid pre-installed | `string` | n/a | yes |
| <a name="input_squid_port"></a> [squid\_port](#input\_squid\_port) | Port Squid listens on | `number` | `3128` | no |
| <a name="input_vector_config_content"></a> [vector\_config\_content](#input\_vector\_config\_content) | Vector log-shipping config (vector.toml) content, written to the config bucket. Nothing on the instance fetches it automatically - the Packer image bakes its own vector.toml in at build time - so applying it requires a custom\_startup\_script that fetches it. Null skips writing the object | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the config bucket |
| <a name="output_instance_group"></a> [instance\_group](#output\_instance\_group) | Self-link of the proxy fleet's managed instance group |
| <a name="output_internal_lb_ip_address"></a> [internal\_lb\_ip\_address](#output\_internal\_lb\_ip\_address) | IP address of the internal load balancer in front of the Squid fleet |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | Name of the access-log bucket |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the proxy fleet's service account |
<!-- END_TF_DOCS -->
