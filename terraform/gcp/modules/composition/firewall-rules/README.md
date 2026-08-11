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
| <a name="module_firewall_rules"></a> [firewall\_rules](#module\_firewall\_rules) | terraform-google-modules/network/google//modules/firewall-rules | 18.1.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the VPC network the rules apply to | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where the firewall rules are created | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for naming resources | `string` | `"hyperswitch"` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of firewall rule groups keyed by logical component name (e.g. "bastion-to-locker").<br/>Each group's rules are flattened and created as VPC firewall rules on var.network\_name.<br/>Rule names are auto-prefixed with "<environment>-<project\_name>-<component>-<rule.name>". | <pre>map(object({<br/>    rules = list(object({<br/>      name                    = string<br/>      description             = optional(string)<br/>      direction               = optional(string, "INGRESS") # INGRESS or EGRESS<br/>      priority                = optional(number, 1000)<br/>      ranges                  = optional(list(string))<br/>      source_tags             = optional(list(string))<br/>      source_service_accounts = optional(list(string))<br/>      target_tags             = optional(list(string))<br/>      target_service_accounts = optional(list(string))<br/>      allow = optional(list(object({<br/>        protocol = string<br/>        ports    = optional(list(string))<br/>      })))<br/>      deny = optional(list(object({<br/>        protocol = string<br/>        ports    = optional(list(string))<br/>      })))<br/>      log_config = optional(object({<br/>        metadata = string<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_firewall_rules"></a> [firewall\_rules](#output\_firewall\_rules) | Map of created firewall rule self-links, keyed by rule name |
| <a name="output_firewall_rules_ingress_egress"></a> [firewall\_rules\_ingress\_egress](#output\_firewall\_rules\_ingress\_egress) | Firewall rule self-links split into ingress\_rules / egress\_rules lists |
| <a name="output_rules_summary"></a> [rules\_summary](#output\_rules\_summary) | Summary of firewall rules created |
<!-- END_TF_DOCS -->
