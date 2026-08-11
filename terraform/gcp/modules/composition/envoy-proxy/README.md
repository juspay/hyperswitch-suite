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
| <a name="module_cloud_armor"></a> [cloud\_armor](#module\_cloud\_armor) | GoogleCloudPlatform/cloud-armor/google | 8.1.1 |
| <a name="module_config_bucket"></a> [config\_bucket](#module\_config\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_config_secret"></a> [config\_secret](#module\_config\_secret) | GoogleCloudPlatform/secret-manager/google | 0.9.0 |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | GoogleCloudPlatform/lb-http/google | 14.2.0 |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |
| <a name="module_proxy_mig"></a> [proxy\_mig](#module\_proxy\_mig) | terraform-google-modules/vm/google//modules/mig | 15.2.1 |
| <a name="module_proxy_template"></a> [proxy\_template](#module\_proxy\_template) | terraform-google-modules/vm/google//modules/instance_template | 15.2.1 |
| <a name="module_service_account"></a> [service\_account](#module\_service\_account) | terraform-google-modules/service-accounts/google | 4.7.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [google_network_security_server_tls_policy.mtls](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_server_tls_policy) | resource |
| [google_storage_bucket_object.envoy_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_autoscaling_cpu_target"></a> [autoscaling\_cpu\_target](#input\_autoscaling\_cpu\_target) | Target CPU utilization (0-1) for the autoscaler | `number` | `0.6` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the config/log buckets | `string` | `"US"` | no |
| <a name="input_cloud_armor_preconfigured_rules"></a> [cloud\_armor\_preconfigured\_rules](#input\_cloud\_armor\_preconfigured\_rules) | Map of Cloud Armor pre-configured WAF rules to enable, in the shape expected by GoogleCloudPlatform/cloud-armor | `any` | `{}` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Boot disk size in GB | `number` | `30` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-balanced"` | no |
| <a name="input_enable_cloud_armor"></a> [enable\_cloud\_armor](#input\_enable\_cloud\_armor) | Whether to create and attach a Cloud Armor WAF policy to the load balancer backend | `bool` | `true` | no |
| <a name="input_enable_mtls_listener"></a> [enable\_mtls\_listener](#input\_enable\_mtls\_listener) | Whether to create the separate regional mTLS Server TLS Policy listener | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_envoy_config_content"></a> [envoy\_config\_content](#input\_envoy\_config\_content) | Envoy config YAML content. Written to both the config bucket and a Secret Manager secret. Null skips both | `string` | `null` | no |
| <a name="input_envoy_image"></a> [envoy\_image](#input\_envoy\_image) | Self-link or family of the custom image with Envoy pre-installed | `string` | n/a | yes |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | HTTP path for the load balancer / MIG health check | `string` | `"/health"` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | Port Envoy listens on for HTTP | `number` | `8080` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | Port Envoy listens on for HTTPS | `number` | `8443` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain access log objects before deletion | `number` | `90` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | Machine type for proxy instances | `string` | `"n2-standard-2"` | no |
| <a name="input_managed_ssl_certificate_domains"></a> [managed\_ssl\_certificate\_domains](#input\_managed\_ssl\_certificate\_domains) | List of domains for the load balancer's Google-managed SSL certificate | `list(string)` | `[]` | no |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | Maximum number of proxy instances | `number` | `10` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Additional instance metadata applied to proxy instances (e.g. startup-script parameters) | `map(string)` | `{}` | no |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | Minimum number of proxy instances | `number` | `2` | no |
| <a name="input_mtls_port"></a> [mtls\_port](#input\_mtls\_port) | Port Envoy listens on for mTLS | `number` | `8444` | no |
| <a name="input_mtls_trust_config_id"></a> [mtls\_trust\_config\_id](#input\_mtls\_trust\_config\_id) | ID of the Certificate Manager TrustConfig used for client certificate validation. Required when enable\_mtls\_listener = true | `string` | `null` | no |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_proxy_subnetwork"></a> [proxy\_subnetwork](#input\_proxy\_subnetwork) | Self-link of the subnetwork for Envoy proxy instances (typically the incoming-envoy tier) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region for regional resources | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloud_armor_policy_id"></a> [cloud\_armor\_policy\_id](#output\_cloud\_armor\_policy\_id) | ID of the Cloud Armor policy, if enabled |
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the config bucket |
| <a name="output_instance_group"></a> [instance\_group](#output\_instance\_group) | Self-link of the proxy fleet's managed instance group |
| <a name="output_load_balancer_ip_address"></a> [load\_balancer\_ip\_address](#output\_load\_balancer\_ip\_address) | External IP address of the Envoy load balancer |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | Name of the access-log bucket |
| <a name="output_mtls_server_tls_policy_id"></a> [mtls\_server\_tls\_policy\_id](#output\_mtls\_server\_tls\_policy\_id) | ID of the mTLS Server TLS Policy, if enabled |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the proxy fleet's service account |
<!-- END_TF_DOCS -->
