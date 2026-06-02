<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_common_internet_rt"></a> [common\_internet\_rt](#module\_common\_internet\_rt) | ../../base/route-table | n/a |
| <a name="module_common_internet_s3_rt"></a> [common\_internet\_s3\_rt](#module\_common\_internet\_s3\_rt) | ../../base/route-table | n/a |
| <a name="module_common_local_nat_s3_rt"></a> [common\_local\_nat\_s3\_rt](#module\_common\_local\_nat\_s3\_rt) | ../../base/route-table | n/a |
| <a name="module_common_local_route_rt"></a> [common\_local\_route\_rt](#module\_common\_local\_route\_rt) | ../../base/route-table | n/a |
| <a name="module_common_local_s3_rt"></a> [common\_local\_s3\_rt](#module\_common\_local\_s3\_rt) | ../../base/route-table | n/a |
| <a name="module_custom_subnets"></a> [custom\_subnets](#module\_custom\_subnets) | ../../base/subnet | n/a |
| <a name="module_data_stack_subnets"></a> [data\_stack\_subnets](#module\_data\_stack\_subnets) | ../../base/subnet | n/a |
| <a name="module_database_route_table"></a> [database\_route\_table](#module\_database\_route\_table) | ../../base/route-table | n/a |
| <a name="module_database_subnets"></a> [database\_subnets](#module\_database\_subnets) | ../../base/subnet | n/a |
| <a name="module_db_route_table"></a> [db\_route\_table](#module\_db\_route\_table) | ../../base/route-table | n/a |
| <a name="module_eks_control_plane_subnets"></a> [eks\_control\_plane\_subnets](#module\_eks\_control\_plane\_subnets) | ../../base/subnet | n/a |
| <a name="module_eks_worker_rt"></a> [eks\_worker\_rt](#module\_eks\_worker\_rt) | ../../base/route-table | n/a |
| <a name="module_eks_workers_subnets"></a> [eks\_workers\_subnets](#module\_eks\_workers\_subnets) | ../../base/subnet | n/a |
| <a name="module_elasticache_subnets"></a> [elasticache\_subnets](#module\_elasticache\_subnets) | ../../base/subnet | n/a |
| <a name="module_external_incoming_subnets"></a> [external\_incoming\_subnets](#module\_external\_incoming\_subnets) | ../../base/subnet | n/a |
| <a name="module_gateway_vpc_endpoints"></a> [gateway\_vpc\_endpoints](#module\_gateway\_vpc\_endpoints) | ../../base/vpc-endpoint | n/a |
| <a name="module_incoming_envoy_subnets"></a> [incoming\_envoy\_subnets](#module\_incoming\_envoy\_subnets) | ../../base/subnet | n/a |
| <a name="module_interface_vpc_endpoints"></a> [interface\_vpc\_endpoints](#module\_interface\_vpc\_endpoints) | ../../base/vpc-endpoint | n/a |
| <a name="module_lambda_subnets"></a> [lambda\_subnets](#module\_lambda\_subnets) | ../../base/subnet | n/a |
| <a name="module_locker_database_subnets"></a> [locker\_database\_subnets](#module\_locker\_database\_subnets) | ../../base/subnet | n/a |
| <a name="module_locker_server_s3_rt"></a> [locker\_server\_s3\_rt](#module\_locker\_server\_s3\_rt) | ../../base/route-table | n/a |
| <a name="module_locker_server_subnets"></a> [locker\_server\_subnets](#module\_locker\_server\_subnets) | ../../base/subnet | n/a |
| <a name="module_main_nacl"></a> [main\_nacl](#module\_main\_nacl) | ../../base/network-acl | n/a |
| <a name="module_management_subnets"></a> [management\_subnets](#module\_management\_subnets) | ../../base/subnet | n/a |
| <a name="module_outgoing_proxy_subnets"></a> [outgoing\_proxy\_subnets](#module\_outgoing\_proxy\_subnets) | ../../base/subnet | n/a |
| <a name="module_proxy_peering_nat_a_rt"></a> [proxy\_peering\_nat\_a\_rt](#module\_proxy\_peering\_nat\_a\_rt) | ../../base/route-table | n/a |
| <a name="module_proxy_peering_nat_b_rt"></a> [proxy\_peering\_nat\_b\_rt](#module\_proxy\_peering\_nat\_b\_rt) | ../../base/route-table | n/a |
| <a name="module_proxy_peering_nat_c_rt"></a> [proxy\_peering\_nat\_c\_rt](#module\_proxy\_peering\_nat\_c\_rt) | ../../base/route-table | n/a |
| <a name="module_redis_route_table"></a> [redis\_route\_table](#module\_redis\_route\_table) | ../../base/route-table | n/a |
| <a name="module_utils_subnets"></a> [utils\_subnets](#module\_utils\_subnets) | ../../base/subnet | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../base/vpc | n/a |
| <a name="module_vpc_endpoint_sg"></a> [vpc\_endpoint\_sg](#module\_vpc\_endpoint\_sg) | ../../base/security-group | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_route.accepter_peering_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.peering_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table_association.data_stack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.eks_control_plane](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.eks_workers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.external_incoming](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.incoming_envoy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.locker_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.locker_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.outgoing_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.utils](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_vpc_peering_connection.requester](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection_accepter.accepter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones to use for subnets | `list(string)` | n/a | yes |
| <a name="input_create_dhcp_options"></a> [create\_dhcp\_options](#input\_create\_dhcp\_options) | Should be true if you want to specify a DHCP options set | `bool` | `false` | no |
| <a name="input_create_internet_gateway"></a> [create\_internet\_gateway](#input\_create\_internet\_gateway) | Controls if an Internet Gateway should be created | `bool` | `true` | no |
| <a name="input_create_nacl"></a> [create\_nacl](#input\_create\_nacl) | Controls if network ACL should be created for all subnets | `bool` | `true` | no |
| <a name="input_create_vpc_endpoint_security_group"></a> [create\_vpc\_endpoint\_security\_group](#input\_create\_vpc\_endpoint\_security\_group) | Whether to create a security group for VPC endpoints | `bool` | `true` | no |
| <a name="input_custom_subnet_groups"></a> [custom\_subnet\_groups](#input\_custom\_subnet\_groups) | Map of custom subnet groups with their configurations | <pre>map(object({<br/>    cidr_block         = string<br/>    availability_zone  = string<br/>    tier               = string<br/>    type               = string<br/>    create_route_table = optional(bool, true)<br/>    create_igw_route   = optional(bool, false)<br/>    create_nat_route   = optional(bool, false)<br/>    tags               = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_data_stack_subnet_cidrs"></a> [data\_stack\_subnet\_cidrs](#input\_data\_stack\_subnet\_cidrs) | List of CIDR blocks for data stack subnets (one per AZ) - S3 endpoint access only | `list(string)` | `[]` | no |
| <a name="input_data_stack_subnet_tags"></a> [data\_stack\_subnet\_tags](#input\_data\_stack\_subnet\_tags) | Additional tags for data stack subnets | `map(string)` | `{}` | no |
| <a name="input_database_subnet_cidrs"></a> [database\_subnet\_cidrs](#input\_database\_subnet\_cidrs) | List of CIDR blocks for database subnets (one per AZ) - fully isolated, no internet | `list(string)` | `[]` | no |
| <a name="input_database_subnet_tags"></a> [database\_subnet\_tags](#input\_database\_subnet\_tags) | Additional tags for database subnets | `map(string)` | `{}` | no |
| <a name="input_dhcp_options_domain_name"></a> [dhcp\_options\_domain\_name](#input\_dhcp\_options\_domain\_name) | Specifies DNS name for DHCP options set | `string` | `""` | no |
| <a name="input_dhcp_options_domain_name_servers"></a> [dhcp\_options\_domain\_name\_servers](#input\_dhcp\_options\_domain\_name\_servers) | Specify a list of DNS server addresses for DHCP options set | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| <a name="input_dhcp_options_ntp_servers"></a> [dhcp\_options\_ntp\_servers](#input\_dhcp\_options\_ntp\_servers) | Specify a list of NTP servers for DHCP options set | `list(string)` | `[]` | no |
| <a name="input_eks_control_plane_subnet_cidrs"></a> [eks\_control\_plane\_subnet\_cidrs](#input\_eks\_control\_plane\_subnet\_cidrs) | List of CIDR blocks for EKS control plane subnets (one per AZ) | `list(string)` | `[]` | no |
| <a name="input_eks_control_plane_subnet_tags"></a> [eks\_control\_plane\_subnet\_tags](#input\_eks\_control\_plane\_subnet\_tags) | Additional tags for EKS control plane subnets | `map(string)` | `{}` | no |
| <a name="input_eks_workers_subnet_cidrs"></a> [eks\_workers\_subnet\_cidrs](#input\_eks\_workers\_subnet\_cidrs) | List of CIDR blocks for EKS worker node subnets (one per AZ) - use /21 for ~2000 IPs per AZ | `list(string)` | `[]` | no |
| <a name="input_eks_workers_subnet_tags"></a> [eks\_workers\_subnet\_tags](#input\_eks\_workers\_subnet\_tags) | Additional tags for EKS worker node subnets | `map(string)` | `{}` | no |
| <a name="input_elasticache_subnet_cidrs"></a> [elasticache\_subnet\_cidrs](#input\_elasticache\_subnet\_cidrs) | List of CIDR blocks for ElastiCache subnets (one per AZ) - fully isolated, no internet | `list(string)` | `[]` | no |
| <a name="input_elasticache_subnet_tags"></a> [elasticache\_subnet\_tags](#input\_elasticache\_subnet\_tags) | Additional tags for ElastiCache subnets | `map(string)` | `{}` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_eks_elb_tag"></a> [enable\_eks\_elb\_tag](#input\_enable\_eks\_elb\_tag) | Enable kubernetes.io/role/elb tag for external incoming subnets (for EKS external load balancers) | `bool` | `true` | no |
| <a name="input_enable_eks_internal_elb_tag"></a> [enable\_eks\_internal\_elb\_tag](#input\_enable\_eks\_internal\_elb\_tag) | Enable kubernetes.io/role/internal-elb tag for EKS worker subnets (for EKS internal load balancers) | `bool` | `true` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VPC Flow Logs | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Requests an Amazon-provided IPv6 CIDR block | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways | `bool` | `true` | no |
| <a name="input_enable_network_address_usage_metrics"></a> [enable\_network\_address\_usage\_metrics](#input\_enable\_network\_address\_usage\_metrics) | Enable network address usage metrics | `bool` | `false` | no |
| <a name="input_enable_vpc_peering_routes"></a> [enable\_vpc\_peering\_routes](#input\_enable\_vpc\_peering\_routes) | Whether to create routes for VPC peering connections | `bool` | `true` | no |
| <a name="input_external_incoming_subnet_cidrs"></a> [external\_incoming\_subnet\_cidrs](#input\_external\_incoming\_subnet\_cidrs) | List of CIDR blocks for external incoming subnets (one per AZ) - for ALB, NAT Gateway | `list(string)` | `[]` | no |
| <a name="input_external_incoming_subnet_tags"></a> [external\_incoming\_subnet\_tags](#input\_external\_incoming\_subnet\_tags) | Additional tags for external incoming subnets | `map(string)` | `{}` | no |
| <a name="input_flow_logs_destination_arn"></a> [flow\_logs\_destination\_arn](#input\_flow\_logs\_destination\_arn) | ARN of CloudWatch Log Group or S3 Bucket for VPC Flow Logs | `string` | `""` | no |
| <a name="input_flow_logs_destination_type"></a> [flow\_logs\_destination\_type](#input\_flow\_logs\_destination\_type) | Type of flow log destination. Valid values: cloud-watch-logs, s3 | `string` | `"cloud-watch-logs"` | no |
| <a name="input_flow_logs_iam_role_arn"></a> [flow\_logs\_iam\_role\_arn](#input\_flow\_logs\_iam\_role\_arn) | ARN of IAM role for VPC Flow Logs | `string` | `""` | no |
| <a name="input_flow_logs_log_format"></a> [flow\_logs\_log\_format](#input\_flow\_logs\_log\_format) | Custom format for VPC Flow Logs | `string` | `null` | no |
| <a name="input_flow_logs_traffic_type"></a> [flow\_logs\_traffic\_type](#input\_flow\_logs\_traffic\_type) | Type of traffic to capture. Valid values: ACCEPT, REJECT, ALL | `string` | `"ALL"` | no |
| <a name="input_gateway_vpc_endpoints"></a> [gateway\_vpc\_endpoints](#input\_gateway\_vpc\_endpoints) | List of gateway VPC endpoints to create (s3, dynamodb) | `list(string)` | `[]` | no |
| <a name="input_include_database_route_tables_in_gateway_endpoints"></a> [include\_database\_route\_tables\_in\_gateway\_endpoints](#input\_include\_database\_route\_tables\_in\_gateway\_endpoints) | Whether to include database subnet route tables in gateway endpoints | `bool` | `false` | no |
| <a name="input_incoming_envoy_subnet_cidrs"></a> [incoming\_envoy\_subnet\_cidrs](#input\_incoming\_envoy\_subnet\_cidrs) | List of CIDR blocks for incoming web envoy subnets (one per AZ) - private with NAT access | `list(string)` | `[]` | no |
| <a name="input_incoming_envoy_subnet_tags"></a> [incoming\_envoy\_subnet\_tags](#input\_incoming\_envoy\_subnet\_tags) | Additional tags for incoming envoy subnets | `map(string)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_interface_vpc_endpoints"></a> [interface\_vpc\_endpoints](#input\_interface\_vpc\_endpoints) | List of interface VPC endpoints to create (ec2, ecr\_api, ecr\_dkr, logs, etc.) | `list(string)` | `[]` | no |
| <a name="input_lambda_subnet_cidrs"></a> [lambda\_subnet\_cidrs](#input\_lambda\_subnet\_cidrs) | List of CIDR blocks for Lambda subnets (one per AZ) - private with NAT and S3 endpoint | `list(string)` | `[]` | no |
| <a name="input_lambda_subnet_tags"></a> [lambda\_subnet\_tags](#input\_lambda\_subnet\_tags) | Additional tags for Lambda subnets | `map(string)` | `{}` | no |
| <a name="input_locker_database_subnet_cidrs"></a> [locker\_database\_subnet\_cidrs](#input\_locker\_database\_subnet\_cidrs) | List of CIDR blocks for locker database subnets (one per AZ) - PCI-DSS compliant, fully isolated | `list(string)` | `[]` | no |
| <a name="input_locker_database_subnet_tags"></a> [locker\_database\_subnet\_tags](#input\_locker\_database\_subnet\_tags) | Additional tags for locker database subnets | `map(string)` | `{}` | no |
| <a name="input_locker_server_subnet_cidrs"></a> [locker\_server\_subnet\_cidrs](#input\_locker\_server\_subnet\_cidrs) | List of CIDR blocks for locker server subnets (one per AZ) - PCI-DSS compliant, fully isolated | `list(string)` | `[]` | no |
| <a name="input_locker_server_subnet_tags"></a> [locker\_server\_subnet\_tags](#input\_locker\_server\_subnet\_tags) | Additional tags for locker server subnets | `map(string)` | `{}` | no |
| <a name="input_manage_default_network_acl"></a> [manage\_default\_network\_acl](#input\_manage\_default\_network\_acl) | Should be true to adopt and manage the default network ACL | `bool` | `true` | no |
| <a name="input_manage_default_route_table"></a> [manage\_default\_route\_table](#input\_manage\_default\_route\_table) | Should be true to manage the default route table | `bool` | `true` | no |
| <a name="input_manage_default_security_group"></a> [manage\_default\_security\_group](#input\_manage\_default\_security\_group) | Should be true to adopt and manage the default security group | `bool` | `true` | no |
| <a name="input_management_subnet_cidrs"></a> [management\_subnet\_cidrs](#input\_management\_subnet\_cidrs) | List of CIDR blocks for management subnets (one per AZ) - for bastion hosts | `list(string)` | `[]` | no |
| <a name="input_management_subnet_tags"></a> [management\_subnet\_tags](#input\_management\_subnet\_tags) | Additional tags for management subnets | `map(string)` | `{}` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Should be false - use Elastic IP for bastion instead of auto-assigned public IP | `bool` | `false` | no |
| <a name="input_outgoing_proxy_subnet_cidrs"></a> [outgoing\_proxy\_subnet\_cidrs](#input\_outgoing\_proxy\_subnet\_cidrs) | List of CIDR blocks for outgoing proxy subnets (one per AZ) - private with NAT access | `list(string)` | `[]` | no |
| <a name="input_outgoing_proxy_subnet_tags"></a> [outgoing\_proxy\_subnet\_tags](#input\_outgoing\_proxy\_subnet\_tags) | Additional tags for outgoing proxy subnets | `map(string)` | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for VPC endpoints | `string` | n/a | yes |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | List of secondary CIDR blocks to associate with the VPC (useful for EKS pod networking) | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all private networks (cost savings) | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_utils_subnet_cidrs"></a> [utils\_subnet\_cidrs](#input\_utils\_subnet\_cidrs) | List of CIDR blocks for utils subnets (one per AZ) - Lambda, Elasticsearch, private with NAT | `list(string)` | `[]` | no |
| <a name="input_utils_subnet_tags"></a> [utils\_subnet\_tags](#input\_utils\_subnet\_tags) | Additional tags for utils subnets | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The IPv4 CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_vpc_endpoint_private_dns_enabled"></a> [vpc\_endpoint\_private\_dns\_enabled](#input\_vpc\_endpoint\_private\_dns\_enabled) | Whether to enable private DNS for VPC endpoints | `bool` | `true` | no |
| <a name="input_vpc_endpoint_security_group_ids"></a> [vpc\_endpoint\_security\_group\_ids](#input\_vpc\_endpoint\_security\_group\_ids) | List of security group IDs to attach to VPC endpoints (only used if create\_vpc\_endpoint\_security\_group is false) | `list(string)` | `[]` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPC | `string` | n/a | yes |
| <a name="input_vpc_peering_accepter_connections"></a> [vpc\_peering\_accepter\_connections](#input\_vpc\_peering\_accepter\_connections) | Map of VPC peering connection IDs to accept (for cross-account peering - run in accepter account) | <pre>map(object({<br/>    peering_connection_id = string<br/>    route_tables          = optional(list(string), ["all"])<br/>    peer_vpc_cidr         = list(string)<br/>    tags                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_peering_connections"></a> [vpc\_peering\_connections](#input\_vpc\_peering\_connections) | Map of VPC peering connection configurations (supports cross-account and cross-region) | <pre>map(object({<br/>    peer_vpc_id   = string<br/>    peer_vpc_cidr = list(string)<br/>    peer_region   = optional(string)<br/>    peer_owner_id = optional(string)<br/>    route_tables  = optional(list(string), ["all"])<br/>    auto_accept   = optional(bool, false)<br/>    tags          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_common_internet_route_table_id"></a> [common\_internet\_route\_table\_id](#output\_common\_internet\_route\_table\_id) | ID of the CommonInternet route table |
| <a name="output_common_internet_s3_route_table_id"></a> [common\_internet\_s3\_route\_table\_id](#output\_common\_internet\_s3\_route\_table\_id) | ID of the CommonInternetS3 route table |
| <a name="output_common_local_nat_s3_route_table_id"></a> [common\_local\_nat\_s3\_route\_table\_id](#output\_common\_local\_nat\_s3\_route\_table\_id) | ID of the Common Local NAT S3 route table (NAT + S3 access) |
| <a name="output_common_local_route_table_id"></a> [common\_local\_route\_table\_id](#output\_common\_local\_route\_table\_id) | ID of the CommonLocalRoute route table |
| <a name="output_common_local_s3_route_table_id"></a> [common\_local\_s3\_route\_table\_id](#output\_common\_local\_s3\_route\_table\_id) | ID of the CommonLocalS3 route table |
| <a name="output_custom_subnet_ids"></a> [custom\_subnet\_ids](#output\_custom\_subnet\_ids) | Map of custom subnet IDs |
| <a name="output_data_stack_subnet_cidr_blocks"></a> [data\_stack\_subnet\_cidr\_blocks](#output\_data\_stack\_subnet\_cidr\_blocks) | List of CIDR blocks of data stack subnets |
| <a name="output_data_stack_subnet_ids"></a> [data\_stack\_subnet\_ids](#output\_data\_stack\_subnet\_ids) | List of IDs of data stack subnets |
| <a name="output_database_route_table_id"></a> [database\_route\_table\_id](#output\_database\_route\_table\_id) | ID of the Database-RT (locker route table) |
| <a name="output_database_subnet_arns"></a> [database\_subnet\_arns](#output\_database\_subnet\_arns) | List of ARNs of database subnets |
| <a name="output_database_subnet_cidr_blocks"></a> [database\_subnet\_cidr\_blocks](#output\_database\_subnet\_cidr\_blocks) | List of CIDR blocks of database subnets |
| <a name="output_database_subnet_ids"></a> [database\_subnet\_ids](#output\_database\_subnet\_ids) | List of IDs of database subnets |
| <a name="output_db_route_table_id"></a> [db\_route\_table\_id](#output\_db\_route\_table\_id) | ID of the DBRouteTable |
| <a name="output_eks_control_plane_subnet_arns"></a> [eks\_control\_plane\_subnet\_arns](#output\_eks\_control\_plane\_subnet\_arns) | List of ARNs of EKS control plane subnets |
| <a name="output_eks_control_plane_subnet_cidr_blocks"></a> [eks\_control\_plane\_subnet\_cidr\_blocks](#output\_eks\_control\_plane\_subnet\_cidr\_blocks) | List of CIDR blocks of EKS control plane subnets |
| <a name="output_eks_control_plane_subnet_ids"></a> [eks\_control\_plane\_subnet\_ids](#output\_eks\_control\_plane\_subnet\_ids) | List of IDs of EKS control plane subnets |
| <a name="output_eks_worker_route_table_id"></a> [eks\_worker\_route\_table\_id](#output\_eks\_worker\_route\_table\_id) | ID of the EKS worker route table (S3 only, no NAT) |
| <a name="output_eks_workers_subnet_arns"></a> [eks\_workers\_subnet\_arns](#output\_eks\_workers\_subnet\_arns) | List of ARNs of EKS worker node subnets |
| <a name="output_eks_workers_subnet_cidr_blocks"></a> [eks\_workers\_subnet\_cidr\_blocks](#output\_eks\_workers\_subnet\_cidr\_blocks) | List of CIDR blocks of EKS worker node subnets |
| <a name="output_eks_workers_subnet_ids"></a> [eks\_workers\_subnet\_ids](#output\_eks\_workers\_subnet\_ids) | List of IDs of EKS worker node subnets |
| <a name="output_elasticache_subnet_arns"></a> [elasticache\_subnet\_arns](#output\_elasticache\_subnet\_arns) | List of ARNs of ElastiCache subnets |
| <a name="output_elasticache_subnet_cidr_blocks"></a> [elasticache\_subnet\_cidr\_blocks](#output\_elasticache\_subnet\_cidr\_blocks) | List of CIDR blocks of ElastiCache subnets |
| <a name="output_elasticache_subnet_ids"></a> [elasticache\_subnet\_ids](#output\_elasticache\_subnet\_ids) | List of IDs of ElastiCache subnets |
| <a name="output_external_incoming_subnet_arns"></a> [external\_incoming\_subnet\_arns](#output\_external\_incoming\_subnet\_arns) | List of ARNs of external incoming subnets |
| <a name="output_external_incoming_subnet_cidr_blocks"></a> [external\_incoming\_subnet\_cidr\_blocks](#output\_external\_incoming\_subnet\_cidr\_blocks) | List of CIDR blocks of external incoming subnets |
| <a name="output_external_incoming_subnet_ids"></a> [external\_incoming\_subnet\_ids](#output\_external\_incoming\_subnet\_ids) | List of IDs of external incoming subnets |
| <a name="output_gateway_vpc_endpoint_ids"></a> [gateway\_vpc\_endpoint\_ids](#output\_gateway\_vpc\_endpoint\_ids) | Map of Gateway VPC Endpoint IDs |
| <a name="output_incoming_envoy_subnet_cidr_blocks"></a> [incoming\_envoy\_subnet\_cidr\_blocks](#output\_incoming\_envoy\_subnet\_cidr\_blocks) | List of CIDR blocks of incoming envoy subnets |
| <a name="output_incoming_envoy_subnet_ids"></a> [incoming\_envoy\_subnet\_ids](#output\_incoming\_envoy\_subnet\_ids) | List of IDs of incoming envoy subnets |
| <a name="output_interface_vpc_endpoint_ids"></a> [interface\_vpc\_endpoint\_ids](#output\_interface\_vpc\_endpoint\_ids) | Map of Interface VPC Endpoint IDs |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | The ID of the Internet Gateway |
| <a name="output_lambda_subnet_arns"></a> [lambda\_subnet\_arns](#output\_lambda\_subnet\_arns) | List of ARNs of lambda subnets |
| <a name="output_lambda_subnet_cidr_blocks"></a> [lambda\_subnet\_cidr\_blocks](#output\_lambda\_subnet\_cidr\_blocks) | List of CIDR blocks of lambda subnets |
| <a name="output_lambda_subnet_ids"></a> [lambda\_subnet\_ids](#output\_lambda\_subnet\_ids) | List of IDs of lambda subnets |
| <a name="output_locker_database_subnet_arns"></a> [locker\_database\_subnet\_arns](#output\_locker\_database\_subnet\_arns) | List of ARNs of locker database subnets |
| <a name="output_locker_database_subnet_cidr_blocks"></a> [locker\_database\_subnet\_cidr\_blocks](#output\_locker\_database\_subnet\_cidr\_blocks) | List of CIDR blocks of locker database subnets |
| <a name="output_locker_database_subnet_ids"></a> [locker\_database\_subnet\_ids](#output\_locker\_database\_subnet\_ids) | List of IDs of locker database subnets |
| <a name="output_locker_server_s3_route_table_id"></a> [locker\_server\_s3\_route\_table\_id](#output\_locker\_server\_s3\_route\_table\_id) | ID of the LockerServerS3 route table |
| <a name="output_locker_server_subnet_cidr_blocks"></a> [locker\_server\_subnet\_cidr\_blocks](#output\_locker\_server\_subnet\_cidr\_blocks) | List of CIDR blocks of locker server subnets |
| <a name="output_locker_server_subnet_ids"></a> [locker\_server\_subnet\_ids](#output\_locker\_server\_subnet\_ids) | List of IDs of locker server subnets |
| <a name="output_management_subnet_cidr_blocks"></a> [management\_subnet\_cidr\_blocks](#output\_management\_subnet\_cidr\_blocks) | List of CIDR blocks of management subnets |
| <a name="output_management_subnet_ids"></a> [management\_subnet\_ids](#output\_management\_subnet\_ids) | List of IDs of management subnets |
| <a name="output_nacl_arn"></a> [nacl\_arn](#output\_nacl\_arn) | ARN of the main network ACL |
| <a name="output_nacl_id"></a> [nacl\_id](#output\_nacl\_id) | ID of the main network ACL |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | List of NAT Gateway IDs |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | List of public IPs of NAT Gateways |
| <a name="output_outgoing_proxy_subnet_cidr_blocks"></a> [outgoing\_proxy\_subnet\_cidr\_blocks](#output\_outgoing\_proxy\_subnet\_cidr\_blocks) | List of CIDR blocks of outgoing proxy subnets |
| <a name="output_outgoing_proxy_subnet_ids"></a> [outgoing\_proxy\_subnet\_ids](#output\_outgoing\_proxy\_subnet\_ids) | List of IDs of outgoing proxy subnets |
| <a name="output_proxy_peering_nat_a_route_table_id"></a> [proxy\_peering\_nat\_a\_route\_table\_id](#output\_proxy\_peering\_nat\_a\_route\_table\_id) | ID of the ProxyPeeringNAT-A route table |
| <a name="output_proxy_peering_nat_b_route_table_id"></a> [proxy\_peering\_nat\_b\_route\_table\_id](#output\_proxy\_peering\_nat\_b\_route\_table\_id) | ID of the ProxyPeeringNAT-B route table |
| <a name="output_proxy_peering_nat_c_route_table_id"></a> [proxy\_peering\_nat\_c\_route\_table\_id](#output\_proxy\_peering\_nat\_c\_route\_table\_id) | ID of the ProxyPeeringNAT-C route table |
| <a name="output_redis_route_table_id"></a> [redis\_route\_table\_id](#output\_redis\_route\_table\_id) | ID of the RedisRouteTable |
| <a name="output_utils_subnet_cidr_blocks"></a> [utils\_subnet\_cidr\_blocks](#output\_utils\_subnet\_cidr\_blocks) | List of CIDR blocks of utils subnets |
| <a name="output_utils_subnet_ids"></a> [utils\_subnet\_ids](#output\_utils\_subnet\_ids) | List of IDs of utils subnets |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | The ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#output\_vpc\_endpoint\_security\_group\_id) | Security group ID for VPC endpoints |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_peering_accepter_ids"></a> [vpc\_peering\_accepter\_ids](#output\_vpc\_peering\_accepter\_ids) | Map of accepted VPC peering connection IDs (accepter side) |
| <a name="output_vpc_peering_connection_accept_status"></a> [vpc\_peering\_connection\_accept\_status](#output\_vpc\_peering\_connection\_accept\_status) | Map of VPC peering connection accept statuses |
| <a name="output_vpc_peering_connection_ids"></a> [vpc\_peering\_connection\_ids](#output\_vpc\_peering\_connection\_ids) | Map of VPC peering connection IDs (requester side) |
| <a name="output_vpc_secondary_cidr_blocks"></a> [vpc\_secondary\_cidr\_blocks](#output\_vpc\_secondary\_cidr\_blocks) | List of secondary CIDR blocks of the VPC |
<!-- END_TF_DOCS -->