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
| <a name="module_cloud_dns"></a> [cloud\_dns](#module\_cloud\_dns) | terraform-google-modules/cloud-dns/google | 7.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_domain"></a> [domain](#input\_domain) | The DNS domain of this zone, e.g. 'dev.hyperswitch.example.com.' (trailing dot required) | `string` | n/a | yes |
| <a name="input_enable_dnssec"></a> [enable\_dnssec](#input\_enable\_dnssec) | Whether to enable DNSSEC. Only applicable to public zones | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to the zone | `map(string)` | `{}` | no |
| <a name="input_private_visibility_config_networks"></a> [private\_visibility\_config\_networks](#input\_private\_visibility\_config\_networks) | List of VPC network self-links this zone is visible from. Required when type = private | `list(string)` | `[]` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the zone is created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name used for labeling resources | `string` | `"hyperswitch"` | no |
| <a name="input_recordsets"></a> [recordsets](#input\_recordsets) | List of DNS recordsets to create in this zone, in the shape expected by terraform-google-modules/cloud-dns | `any` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Zone type: public or private | `string` | `"private"` | no |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Name of the Cloud DNS managed zone (DNS-safe identifier, not the domain itself) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_domain"></a> [domain](#output\_domain) | Domain of the zone |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers assigned to the zone (only meaningful for public zones) |
| <a name="output_type"></a> [type](#output\_type) | Type of the zone |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Name of the managed zone |
<!-- END_TF_DOCS -->
