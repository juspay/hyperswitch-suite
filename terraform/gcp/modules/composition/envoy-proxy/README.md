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
| [google_compute_url_map.envoy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [google_network_security_server_tls_policy.mtls](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/network_security_server_tls_policy) | resource |
| [google_storage_bucket_object.additional_config_files](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.envoy_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_config_files_path"></a> [additional\_config\_files\_path](#input\_additional\_config\_files\_path) | Optional local directory whose files are uploaded verbatim to the config bucket alongside envoy.yaml (e.g. a vector.toml override). No placeholder templating is applied. "envoy.yaml" is skipped, since envoy\_config\_content already owns that object. Null skips this entirely | `string` | `null` | no |
| <a name="input_bucket_location"></a> [bucket\_location](#input\_bucket\_location) | Location for the config/log buckets | `string` | `"US"` | no |
| <a name="input_cloud_armor_preconfigured_rules"></a> [cloud\_armor\_preconfigured\_rules](#input\_cloud\_armor\_preconfigured\_rules) | Map of Cloud Armor pre-configured WAF rules to enable, in the shape expected by GoogleCloudPlatform/cloud-armor | `any` | `{}` | no |
| <a name="input_custom_startup_script"></a> [custom\_startup\_script](#input\_custom\_startup\_script) | GCE startup-script content run on boot - fetches envoy.yaml/vector.toml from the config bucket and (re)starts envoy.service/vector.service. No placeholder substitution happens here; the script reads the config-bucket key from the instance metadata server itself. Null sets no startup-script, leaving the instance to boot on whatever the image bakes in | `string` | `null` | no |
| <a name="input_deployments"></a> [deployments](#input\_deployments) | Map of concurrent Envoy deployments for blue/green and canary rollouts.<br/>Each key is an identifier (e.g. "stable", "canary"). Traffic is split<br/>across them via the load balancer's weighted\_backend\_services - GCP<br/>normalizes each deployment's share as weight / sum(all weights), so<br/>weights don't need to sum to 100 the way AWS's ALB weighted-forward<br/>percentages conventionally do (they still can, that's just not<br/>required).<br/><br/>Fields left unset on a deployment fall back to the module-level<br/>envoy\_image/machine\_type/min\_replicas/max\_replicas variables - same<br/>override-or-inherit pattern as the AWS module's deployments map. | <pre>map(object({<br/>    weight       = number<br/>    envoy_image  = optional(string)<br/>    machine_type = optional(string)<br/>    min_replicas = optional(number)<br/>    max_replicas = optional(number)<br/>  }))</pre> | <pre>{<br/>  "stable": {<br/>    "weight": 100<br/>  }<br/>}</pre> | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Boot disk size in GB | `number` | `30` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Persistent disk type | `string` | `"pd-balanced"` | no |
| <a name="input_enable_cdn"></a> [enable\_cdn](#input\_enable\_cdn) | Whether to enable Cloud CDN on the load balancer's backend. Cloud CDN attaches directly to the existing backend rather than creating a separate distribution, so the LB's own IP becomes CDN-accelerated. Uses cache\_mode = CACHE\_ALL\_STATIC, since this backend also serves non-cacheable payment API traffic | `bool` | `false` | no |
| <a name="input_enable_cloud_armor"></a> [enable\_cloud\_armor](#input\_enable\_cloud\_armor) | Whether to create and attach a Cloud Armor WAF policy to the load balancer backend | `bool` | `true` | no |
| <a name="input_enable_https_redirect"></a> [enable\_https\_redirect](#input\_enable\_https\_redirect) | Whether the LB force-redirects HTTP to HTTPS. Defaults true (the<br/>correct posture once a real domain + validated managed cert exist).<br/>Set false only when managed\_ssl\_certificate\_domains is a placeholder<br/>that will never validate (e.g. no real DNS pointed at the LB yet) -<br/>otherwise port 80 just redirects into a TLS handshake that can never<br/>complete, and the LB is untestable end-to-end from outside the VPC. | `bool` | `true` | no |
| <a name="input_enable_mtls_listener"></a> [enable\_mtls\_listener](#input\_enable\_mtls\_listener) | Whether to create the separate regional mTLS Server TLS Policy listener | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_envoy_config_content"></a> [envoy\_config\_content](#input\_envoy\_config\_content) | Envoy config YAML content. Written to both the config bucket and a Secret Manager secret. Null skips both | `string` | `null` | no |
| <a name="input_envoy_image"></a> [envoy\_image](#input\_envoy\_image) | Custom image with Envoy pre-installed - either a full self-link (projects/P/global/images/I) or a bare image name in var.project\_id. Must be a specific image, not an image family | `string` | n/a | yes |
| <a name="input_force_destroy_buckets"></a> [force\_destroy\_buckets](#input\_force\_destroy\_buckets) | Whether the config/log buckets can be destroyed while non-empty - required for `terraform destroy` to succeed at all, since versioning leaves noncurrent object versions behind. Null (default) auto-derives: true everywhere except "prod" | `bool` | `null` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | HTTP path for the load balancer / MIG health check | `string` | `"/health"` | no |
| <a name="input_http_port"></a> [http\_port](#input\_http\_port) | Port Envoy listens on for HTTP | `number` | `8080` | no |
| <a name="input_https_port"></a> [https\_port](#input\_https\_port) | Port Envoy listens on for HTTPS | `number` | `8443` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Advanced load-balancer routing rules, evaluated before the default<br/>weighted deployment split, for path/host/header-based routing or<br/>redirects at the load balancer layer (before traffic reaches Envoy).<br/><br/>Rules are evaluated in ascending priority order (lower number = higher<br/>precedence), matching the AWS ALB listener\_rules priority convention.<br/>A rule with host = null applies regardless of host; a rule with host<br/>set only applies to hostnames in that list (GCP routes host-scoped<br/>rules through a dedicated path\_matcher selected by a host\_rule - see<br/>locals.path\_matchers).<br/><br/>Only one of path\_prefix / path\_exact may be set per rule. headers<br/>entries with more than one value are OR'd together via a regex<br/>alternation (values are NOT regex-escaped - avoid regex metacharacters<br/>in header values unless an alternation pattern is intended).<br/><br/>Source-IP-based routing is NOT supported: GCP's HTTP(S) load balancer<br/>URL map has no source-IP match dimension at the routing layer (Cloud<br/>Armor can allow/deny by source IP at the edge, but cannot route a<br/>matched request to a different backend) - the AWS module's source\_ip<br/>listener\_rules condition has no equivalent field here.<br/><br/>action.type = "forward" routes matching requests to a specific<br/>deployment's backend service (action.target\_deployment, required, must<br/>be a key in var.deployments), bypassing the weighted split entirely.<br/>action.type = "redirect" returns an HTTP redirect without forwarding<br/>to any backend. | <pre>list(object({<br/>    priority    = number<br/>    host        = optional(list(string))<br/>    path_prefix = optional(string)<br/>    path_exact  = optional(string)<br/>    headers = optional(list(object({<br/>      name   = string<br/>      values = list(string)<br/>    })), [])<br/>    action = object({<br/>      type              = string<br/>      target_deployment = optional(string)<br/>      redirect = optional(object({<br/>        host          = optional(string)<br/>        path          = optional(string)<br/>        https         = optional(bool, true)<br/>        response_code = optional(string, "MOVED_PERMANENTLY_DEFAULT")<br/>      }))<br/>    })<br/>  }))</pre> | `[]` | no |
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
| <a name="input_scaling_policies"></a> [scaling\_policies](#input\_scaling\_policies) | Autoscaling policy configuration, applied to every deployment's MIG.<br/><br/>cpu\_target\_tracking uses the MIG autoscaler's built-in CPU utilization<br/>signal (target\_value is a 0-1 fraction, e.g. 0.6 = 60%). Enabled by<br/>default to preserve this module's previous always-on CPU autoscaling<br/>behavior.<br/><br/>memory\_target\_tracking uses a custom Cloud Monitoring metric<br/>(agent.googleapis.com/memory/percent\_used, a 0-100 gauge - note the<br/>different scale from cpu\_target\_tracking's 0-1 fraction). This<br/>requires the Ops Agent to be installed and configured on the Envoy<br/>image - enabling this without the agent present means the autoscaler<br/>never receives the metric and this policy is a silent no-op, the same<br/>precondition the AWS module documents for its CloudWatch-agent-backed<br/>memory\_target\_tracking. Installing the Ops Agent is out of scope for<br/>this module; see terraform/gcp/packer/envoy-proxy's README.<br/><br/>If both signals are disabled, the MIG's target\_size (== min\_replicas)<br/>is used as a static instance count with no autoscaler attached. | <pre>object({<br/>    cpu_target_tracking = optional(object({<br/>      enabled      = optional(bool, true)<br/>      target_value = optional(number, 0.6)<br/>    }), {})<br/>    memory_target_tracking = optional(object({<br/>      enabled      = optional(bool, false)<br/>      target_value = optional(number, 70)<br/>    }), {})<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cloud_armor_policy_id"></a> [cloud\_armor\_policy\_id](#output\_cloud\_armor\_policy\_id) | ID of the Cloud Armor policy, if enabled |
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the config bucket |
| <a name="output_deployment_weights"></a> [deployment\_weights](#output\_deployment\_weights) | Map of deployment name to its configured load-balancer traffic weight |
| <a name="output_instance_groups"></a> [instance\_groups](#output\_instance\_groups) | Map of deployment name to that deployment's managed instance group self-link |
| <a name="output_load_balancer_ip_address"></a> [load\_balancer\_ip\_address](#output\_load\_balancer\_ip\_address) | External IP address of the Envoy load balancer |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | Name of the access-log bucket |
| <a name="output_mtls_server_tls_policy_id"></a> [mtls\_server\_tls\_policy\_id](#output\_mtls\_server\_tls\_policy\_id) | ID of the mTLS Server TLS Policy, if enabled |
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the proxy fleet's service account |
| <a name="output_url_map_id"></a> [url\_map\_id](#output\_url\_map\_id) | ID of the module-managed URL map handling weighted deployment routing and listener\_rules |
<!-- END_TF_DOCS -->
