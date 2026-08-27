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

No modules.

## Resources

| Name | Type |
|------|------|
| [google_filestore_backup.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_backup) | resource |
| [google_filestore_instance.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/filestore_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_instances"></a> [instances](#input\_instances) | Map of Filestore instances to create, keyed by logical name | <pre>map(object({<br/>    zone              = string<br/>    network           = string<br/>    tier              = optional(string, "BASIC_HDD") # BASIC_HDD, BASIC_SSD, ZONAL, REGIONAL, ENTERPRISE<br/>    description       = optional(string)<br/>    connect_mode      = optional(string, "DIRECT_PEERING")<br/>    reserved_ip_range = optional(string)<br/>    kms_key_name      = optional(string)<br/>    create_backup     = optional(bool, false)<br/>    backup_region     = optional(string)<br/>    labels            = optional(map(string), {})<br/>    shares = list(object({<br/>      name        = string<br/>      capacity_gb = number<br/>      nfs_export_options = optional(list(object({<br/>        ip_ranges   = list(string)<br/>        access_mode = optional(string, "READ_WRITE")<br/>        squash_mode = optional(string, "NO_ROOT_SQUASH")<br/>      })), [])<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to every instance | `map(string)` | `{}` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where Filestore instances are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and labeling | `string` | `"hyperswitch"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_ids"></a> [backup\_ids](#output\_backup\_ids) | Map of instance key to its backup ID, for instances with create\_backup = true |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | Map of instance key to its fully qualified ID |
| <a name="output_instance_ip_addresses"></a> [instance\_ip\_addresses](#output\_instance\_ip\_addresses) | Map of instance key to its list of file-share IP addresses |
<!-- END_TF_DOCS -->
