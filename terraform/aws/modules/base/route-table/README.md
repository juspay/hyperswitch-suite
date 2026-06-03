<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route.internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.vpc_peering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_internet_gateway_route"></a> [create\_internet\_gateway\_route](#input\_create\_internet\_gateway\_route) | Whether to create a route to the internet gateway | `bool` | `false` | no |
| <a name="input_create_nat_gateway_route"></a> [create\_nat\_gateway\_route](#input\_create\_nat\_gateway\_route) | Whether to create a route to a NAT gateway | `bool` | `false` | no |
| <a name="input_create_vpc_peering_route"></a> [create\_vpc\_peering\_route](#input\_create\_vpc\_peering\_route) | Whether to create a route to a VPC peering connection | `bool` | `false` | no |
| <a name="input_internet_gateway_id"></a> [internet\_gateway\_id](#input\_internet\_gateway\_id) | ID of the internet gateway | `string` | `""` | no |
| <a name="input_nat_gateway_id"></a> [nat\_gateway\_id](#input\_nat\_gateway\_id) | ID of the NAT gateway to route traffic through | `string` | `""` | no |
| <a name="input_route_table_name"></a> [route\_table\_name](#input\_route\_table\_name) | Name of the route table | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID | `string` | n/a | yes |
| <a name="input_vpc_peering_connection_id"></a> [vpc\_peering\_connection\_id](#input\_vpc\_peering\_connection\_id) | ID of the VPC peering connection | `string` | `""` | no |
| <a name="input_vpc_peering_destination_cidr"></a> [vpc\_peering\_destination\_cidr](#input\_vpc\_peering\_destination\_cidr) | Destination CIDR block for VPC peering route | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_route_table_arn"></a> [route\_table\_arn](#output\_route\_table\_arn) | The ARN of the route table |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | The ID of the route table |
| <a name="output_route_table_owner_id"></a> [route\_table\_owner\_id](#output\_route\_table\_owner\_id) | The ID of the AWS account that owns the route table |
<!-- END_TF_DOCS -->