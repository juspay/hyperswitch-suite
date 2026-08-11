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

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_certificate_manager_certificate.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate) | resource |
| [google_certificate_manager_certificate_map.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_map) | resource |
| [google_certificate_manager_certificate_map_entry.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_certificate_map_entry) | resource |
| [google_certificate_manager_dns_authorization.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/certificate_manager_dns_authorization) | resource |
| [google_compute_managed_ssl_certificate.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Map of certificate configurations. Each key represents a certificate name.<br/>Example:<br/>certificates = {<br/>  "api" = {<br/>    domain\_name               = "api.dev.hyperswitch.example.com"<br/>    subject\_alternative\_names = []<br/>    validation\_method         = "DNS"<br/>  }<br/>} | <pre>map(object({<br/>    domain_name                    = string<br/>    subject_alternative_names      = optional(list(string), [])<br/>    validation_method              = optional(string, "DNS")<br/>    create_classic_ssl_certificate = optional(bool, false)<br/>    labels                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_create_certificate_map"></a> [create\_certificate\_map](#input\_create\_certificate\_map) | Whether to create a Certificate Manager certificate map + entry per certificate, for attaching to a target proxy via certificate\_map | `bool` | `true` | no |
| <a name="input_dns_authorization_type"></a> [dns\_authorization\_type](#input\_dns\_authorization\_type) | DNS authorization type: FIXED\_RECORD or PER\_PROJECT\_RECORD | `string` | `"FIXED_RECORD"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where certificates are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming | `string` | `"hyperswitch"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certificate_ids"></a> [certificate\_ids](#output\_certificate\_ids) | Map of certificate key to its Certificate Manager certificate ID |
| <a name="output_certificate_map_ids"></a> [certificate\_map\_ids](#output\_certificate\_map\_ids) | Map of certificate key to its certificate map ID, for attaching to a target proxy's certificate\_map |
| <a name="output_classic_ssl_certificate_ids"></a> [classic\_ssl\_certificate\_ids](#output\_classic\_ssl\_certificate\_ids) | Map of certificate key to its classic google\_compute\_managed\_ssl\_certificate ID, for callers using the classic target-proxy ssl\_certificates attribute |
| <a name="output_dns_authorization_records"></a> [dns\_authorization\_records](#output\_dns\_authorization\_records) | Map of domain to the DNS record {type, name, data} that must be published (e.g. via composition/cloud-dns) to complete DNS authorization - the equivalent of ACM's validation CNAME |
<!-- END_TF_DOCS -->
