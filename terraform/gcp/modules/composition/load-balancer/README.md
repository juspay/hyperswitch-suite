<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_external_lb"></a> [external\_lb](#module\_external\_lb) | GoogleCloudPlatform/lb-http/google | 14.2.0 |
| <a name="module_internal_lb"></a> [internal\_lb](#module\_internal\_lb) | terraform-google-modules/lb-internal/google | 7.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backends"></a> [backends](#input\_backends) | Backend service configuration for the external load balancer, in the shape expected by GoogleCloudPlatform/lb-http/google | `any` | `{}` | no |
| <a name="input_certificate_map"></a> [certificate\_map](#input\_certificate\_map) | Certificate Manager certificate map ID to attach instead of a classic managed SSL certificate (see composition/certificate-manager) | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether this is an internal (regional TCP/UDP) load balancer instead of an external (global HTTP(S)) one | `bool` | `false` | no |
| <a name="input_internal_backends"></a> [internal\_backends](#input\_internal\_backends) | List of {group = <instance-group-self-link>} backends for the internal load balancer | `any` | `[]` | no |
| <a name="input_internal_lb_health_check"></a> [internal\_lb\_health\_check](#input\_internal\_lb\_health\_check) | Health check configuration for the internal load balancer, in the shape expected by terraform-google-modules/lb-internal | `any` | <pre>{<br/>  "check_interval_sec": 10,<br/>  "healthy_threshold": 2,<br/>  "port": 80,<br/>  "timeout_sec": 5,<br/>  "type": "http",<br/>  "unhealthy_threshold": 3<br/>}</pre> | no |
| <a name="input_internal_lb_ports"></a> [internal\_lb\_ports](#input\_internal\_lb\_ports) | List of ports to forward for the internal load balancer | `list(string)` | `[]` | no |
| <a name="input_internal_lb_source_tags"></a> [internal\_lb\_source\_tags](#input\_internal\_lb\_source\_tags) | Source network tags for the internal load balancer's firewall rules | `list(string)` | `[]` | no |
| <a name="input_internal_lb_target_tags"></a> [internal\_lb\_target\_tags](#input\_internal\_lb\_target\_tags) | Target network tags for the internal load balancer's firewall rules | `list(string)` | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_managed_ssl_certificate_domains"></a> [managed\_ssl\_certificate\_domains](#input\_managed\_ssl\_certificate\_domains) | List of domains for the Google-managed SSL certificate, used when ssl = true and certificate\_map is null | `list(string)` | `[]` | no |
| <a name="input_name_override"></a> [name\_override](#input\_name\_override) | Logical name for this load balancer instance (e.g. 'api', 'admin'), used in resource naming | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Self-link of the VPC network | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the load balancer is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_region"></a> [region](#input\_region) | Region, required when internal = true | `string` | `null` | no |
| <a name="input_ssl"></a> [ssl](#input\_ssl) | Whether to provision an HTTPS listener with a managed certificate and redirect HTTP to HTTPS | `bool` | `true` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | Self-link of the subnetwork, required when internal = true | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_external_ip_address"></a> [external\_ip\_address](#output\_external\_ip\_address) | External IP address of the global HTTP(S) load balancer, if internal = false |
| <a name="output_internal_ip_address"></a> [internal\_ip\_address](#output\_internal\_ip\_address) | IP address of the internal load balancer, if internal = true |
<!-- END_TF_DOCS -->
