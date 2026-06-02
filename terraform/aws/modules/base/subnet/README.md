<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assign_ipv6_address_on_creation"></a> [assign\_ipv6\_address\_on\_creation](#input\_assign\_ipv6\_address\_on\_creation) | Specify true to indicate that network interfaces created in the subnet should be assigned an IPv6 address | `bool` | `false` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The AZ for the subnet | `string` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The IPv4 CIDR block for the subnet | `string` | n/a | yes |
| <a name="input_create_internet_gateway_route"></a> [create\_internet\_gateway\_route](#input\_create\_internet\_gateway\_route) | Whether to create a route to the internet gateway | `bool` | `false` | no |
| <a name="input_create_nat_gateway"></a> [create\_nat\_gateway](#input\_create\_nat\_gateway) | Whether to create a NAT gateway in this subnet | `bool` | `false` | no |
| <a name="input_create_nat_gateway_route"></a> [create\_nat\_gateway\_route](#input\_create\_nat\_gateway\_route) | Whether to create a route to a NAT gateway | `bool` | `false` | no |
| <a name="input_create_route_table"></a> [create\_route\_table](#input\_create\_route\_table) | Whether to create a route table for this subnet | `bool` | `true` | no |
| <a name="input_customer_owned_ipv4_pool"></a> [customer\_owned\_ipv4\_pool](#input\_customer\_owned\_ipv4\_pool) | The customer owned IPv4 address pool | `string` | `null` | no |
| <a name="input_enable_dns64"></a> [enable\_dns64](#input\_enable\_dns64) | Indicates whether DNS queries made to the Amazon-provided DNS Resolver return synthetic IPv6 addresses for IPv4-only destinations | `bool` | `false` | no |
| <a name="input_enable_resource_name_dns_a_record_on_launch"></a> [enable\_resource\_name\_dns\_a\_record\_on\_launch](#input\_enable\_resource\_name\_dns\_a\_record\_on\_launch) | Indicates whether to respond to DNS queries for instance hostnames with DNS A records | `bool` | `false` | no |
| <a name="input_enable_resource_name_dns_aaaa_record_on_launch"></a> [enable\_resource\_name\_dns\_aaaa\_record\_on\_launch](#input\_enable\_resource\_name\_dns\_aaaa\_record\_on\_launch) | Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records | `bool` | `false` | no |
| <a name="input_internet_gateway_id"></a> [internet\_gateway\_id](#input\_internet\_gateway\_id) | ID of the internet gateway | `string` | `""` | no |
| <a name="input_ipv6_cidr_block"></a> [ipv6\_cidr\_block](#input\_ipv6\_cidr\_block) | The IPv6 CIDR block for the subnet | `string` | `null` | no |
| <a name="input_map_customer_owned_ip_on_launch"></a> [map\_customer\_owned\_ip\_on\_launch](#input\_map\_customer\_owned\_ip\_on\_launch) | Specify true to indicate that network interfaces created in the subnet should be assigned a customer owned IP address | `bool` | `null` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Specify true to indicate that instances launched into the subnet should be assigned a public IP address | `bool` | `false` | no |
| <a name="input_nat_gateway_connectivity_type"></a> [nat\_gateway\_connectivity\_type](#input\_nat\_gateway\_connectivity\_type) | Connectivity type for the NAT gateway. Valid values: private, public | `string` | `"public"` | no |
| <a name="input_nat_gateway_eip_allocation_id"></a> [nat\_gateway\_eip\_allocation\_id](#input\_nat\_gateway\_eip\_allocation\_id) | Allocation ID of EIP for NAT gateway | `string` | `""` | no |
| <a name="input_nat_gateway_id"></a> [nat\_gateway\_id](#input\_nat\_gateway\_id) | ID of the NAT gateway to route traffic through | `string` | `""` | no |
| <a name="input_outpost_arn"></a> [outpost\_arn](#input\_outpost\_arn) | The ARN of the Outpost | `string` | `null` | no |
| <a name="input_private_dns_hostname_type_on_launch"></a> [private\_dns\_hostname\_type\_on\_launch](#input\_private\_dns\_hostname\_type\_on\_launch) | The type of hostnames to assign to instances in the subnet at launch | `string` | `null` | no |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | ID of existing route table to associate with subnet (only used if create\_route\_table is false) | `string` | `""` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of the subnet | `string` | n/a | yes |
| <a name="input_subnet_tier"></a> [subnet\_tier](#input\_subnet\_tier) | Tier of the subnet (e.g., public, private, database, cache) | `string` | `""` | no |
| <a name="input_subnet_type"></a> [subnet\_type](#input\_subnet\_type) | Type of the subnet (e.g., public, private-nat, private-isolated) | `string` | `"private"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nat_gateway_id"></a> [nat\_gateway\_id](#output\_nat\_gateway\_id) | The ID of the NAT Gateway |
| <a name="output_nat_gateway_private_ip"></a> [nat\_gateway\_private\_ip](#output\_nat\_gateway\_private\_ip) | The private IP address of the NAT Gateway |
| <a name="output_nat_gateway_public_ip"></a> [nat\_gateway\_public\_ip](#output\_nat\_gateway\_public\_ip) | The public IP address of the NAT Gateway |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | The ID of the route table |
| <a name="output_subnet_arn"></a> [subnet\_arn](#output\_subnet\_arn) | The ARN of the subnet |
| <a name="output_subnet_availability_zone"></a> [subnet\_availability\_zone](#output\_subnet\_availability\_zone) | The AZ of the subnet |
| <a name="output_subnet_availability_zone_id"></a> [subnet\_availability\_zone\_id](#output\_subnet\_availability\_zone\_id) | The AZ ID of the subnet |
| <a name="output_subnet_cidr_block"></a> [subnet\_cidr\_block](#output\_subnet\_cidr\_block) | The CIDR block of the subnet |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | The ID of the subnet |
| <a name="output_subnet_ipv6_cidr_block"></a> [subnet\_ipv6\_cidr\_block](#output\_subnet\_ipv6\_cidr\_block) | The IPv6 CIDR block of the subnet |
<!-- END_TF_DOCS -->