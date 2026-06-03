<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_route53_zones"></a> [route53\_zones](#input\_route53\_zones) | Map of Route53 zones to create with their records | <pre>map(object({<br/>    name              = string<br/>    comment           = optional(string, null)<br/>    force_destroy     = optional(bool, false)<br/>    delegation_set_id = optional(string, null)<br/>    vpc = optional(object({<br/>      vpc_id     = string<br/>      vpc_region = optional(string, null)<br/>    }), null)<br/>    tags = optional(map(string), {})<br/>    records = optional(map(object({<br/>      name    = string<br/>      type    = string<br/>      ttl     = optional(number, 300)<br/>      records = optional(list(string), null)<br/>      alias = optional(object({<br/>        name                   = string<br/>        zone_id                = string<br/>        evaluate_target_health = optional(bool, false)<br/>      }), null)<br/>      health_check_id = optional(string, null)<br/>      set_identifier  = optional(string, null)<br/>      allow_overwrite = optional(bool, false)<br/>      weighted_routing_policy = optional(object({<br/>        weight = number<br/>      }), null)<br/>      failover_routing_policy = optional(object({<br/>        type = string<br/>      }), null)<br/>      geolocation_routing_policy = optional(object({<br/>        continent   = optional(string, null)<br/>        country     = optional(string, null)<br/>        subdivision = optional(string, null)<br/>      }), null)<br/>      latency_routing_policy = optional(object({<br/>        region = string<br/>      }), null)<br/>      cidr_routing_policy = optional(object({<br/>        collection_id = string<br/>        location_name = string<br/>      }), null)<br/>      geoproximity_routing_policy = optional(object({<br/>        aws_region       = optional(string, null)<br/>        bias             = optional(number, null)<br/>        local_zone_group = optional(string, null)<br/>        coordinates = optional(object({<br/>          latitude  = string<br/>          longitude = string<br/>        }), null)<br/>      }), null)<br/>      multivalue_answer_routing_policy = optional(bool, null)<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Map of zone names to list of name servers |
| <a name="output_record_fqdns"></a> [record\_fqdns](#output\_record\_fqdns) | Map of record keys to FQDNs |
| <a name="output_record_names"></a> [record\_names](#output\_record\_names) | Map of record keys to record names |
| <a name="output_summary"></a> [summary](#output\_summary) | Summary of Route53 zones and records created |
| <a name="output_zone_arns"></a> [zone\_arns](#output\_zone\_arns) | Map of zone names to zone ARNs |
| <a name="output_zone_ids"></a> [zone\_ids](#output\_zone\_ids) | Map of zone names to zone IDs |
| <a name="output_zone_ids_by_name"></a> [zone\_ids\_by\_name](#output\_zone\_ids\_by\_name) | Map of zone names to zone IDs |
<!-- END_TF_DOCS -->