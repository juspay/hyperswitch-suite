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
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | terraform-google-modules/cloud-storage/google//modules/simple_bucket | 12.3.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_backend_bucket.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_bucket) | resource |
| [google_compute_global_address.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.http](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_global_forwarding_rule.https](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_managed_ssl_certificate.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |
| [google_compute_target_http_proxy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy) | resource |
| [google_compute_target_https_proxy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.https_redirect](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [google_compute_url_map.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backend_buckets"></a> [backend\_buckets](#input\_backend\_buckets) | Map of GCS-origin backends to create, keyed by logical name | <pre>map(object({<br/>    bucket_name       = string<br/>    enable_cdn        = optional(bool, true)<br/>    cache_mode        = optional(string, "CACHE_ALL_STATIC")<br/>    default_ttl       = optional(number, 3600)<br/>    client_ttl        = optional(number, 3600)<br/>    max_ttl           = optional(number, 86400)<br/>    negative_caching  = optional(bool, true)<br/>    serve_while_stale = optional(number, 86400)<br/>  }))</pre> | `{}` | no |
| <a name="input_certificate_map"></a> [certificate\_map](#input\_certificate\_map) | Certificate Manager certificate map ID to attach instead of a classic managed SSL certificate (see composition/certificate-manager) | `string` | `null` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Whether to create a GCS bucket for CDN access logs | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_http_redirect_to_https"></a> [http\_redirect\_to\_https](#input\_http\_redirect\_to\_https) | Whether the HTTP listener redirects to HTTPS instead of serving the same url\_map | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_log_bucket_location"></a> [log\_bucket\_location](#input\_log\_bucket\_location) | Location for the CDN log bucket | `string` | `"US"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CDN log objects before deletion | `number` | `90` | no |
| <a name="input_managed_ssl_certificate_domains"></a> [managed\_ssl\_certificate\_domains](#input\_managed\_ssl\_certificate\_domains) | List of domains for the Google-managed SSL certificate, used when ssl = true and certificate\_map is null | `list(string)` | `[]` | no |
| <a name="input_name_override"></a> [name\_override](#input\_name\_override) | Logical name for this distribution (e.g. 'assets', 'dashboard') | `string` | `"default"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where CDN resources are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_ssl"></a> [ssl](#input\_ssl) | Whether to provision an HTTPS listener | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_bucket_ids"></a> [backend\_bucket\_ids](#output\_backend\_bucket\_ids) | Map of backend bucket key to its resource ID |
| <a name="output_ip_address"></a> [ip\_address](#output\_ip\_address) | Anycast IP address serving this distribution |
| <a name="output_log_bucket_name"></a> [log\_bucket\_name](#output\_log\_bucket\_name) | Name of the CDN log bucket, if enabled |
| <a name="output_url_map_id"></a> [url\_map\_id](#output\_url\_map\_id) | ID of the URL map |
<!-- END_TF_DOCS -->
