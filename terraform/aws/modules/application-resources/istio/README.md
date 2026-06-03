<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.28 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.28 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_security_group.lb_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [helm_release.istio_base](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istio_gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.istiod](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_ingress_v1.istio_gateway](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_helm_releases"></a> [create\_helm\_releases](#input\_create\_helm\_releases) | Whether to create the Helm releases for Istio components | `bool` | `true` | no |
| <a name="input_create_lb_security_group"></a> [create\_lb\_security\_group](#input\_create\_lb\_security\_group) | This creates a security group to attach to load-balancer through annotations | `bool` | `true` | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_host_domains"></a> [host\_domains](#input\_host\_domains) | Map of environment names to list of host domains for the Istio Gateway. Example: { integ = ['integ.example.com'], sandbox = ['sandbox.example.com'] } | `map(list(string))` | `{}` | no |
| <a name="input_ingress_annotations"></a> [ingress\_annotations](#input\_ingress\_annotations) | Additional annotations to be added to ingress resources | `map(string)` | `{}` | no |
| <a name="input_istio_base"></a> [istio\_base](#input\_istio\_base) | Configurations for Istio Base Chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_istio_gateway"></a> [istio\_gateway](#input\_istio\_gateway) | Configurations for Istio Gateway Chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_istio_namespace"></a> [istio\_namespace](#input\_istio\_namespace) | Namespace to install Istio components | `string` | `"istio-system"` | no |
| <a name="input_istiod"></a> [istiod](#input\_istiod) | Configurations for Istiod Chart | <pre>object({<br/>    enabled       = bool<br/>    release_name  = optional(string)<br/>    chart_repo    = optional(string)<br/>    chart_version = optional(string)<br/>    values        = optional(list(string), [])<br/>    values_file   = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_lb_security_groups"></a> [lb\_security\_groups](#input\_lb\_security\_groups) | Existing security group to attach to load-balancer | `list(string)` | `[]` | no |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | Subnet IDs to use for Istio Gateway Load Balancer | `list(string)` | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the security group will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster |
| <a name="output_host_domains_map"></a> [host\_domains\_map](#output\_host\_domains\_map) | Map of environment names to list of host domains for Istio Gateway |
| <a name="output_lb_security_group_id"></a> [lb\_security\_group\_id](#output\_lb\_security\_group\_id) | ID of the created load balancer security group |
| <a name="output_region"></a> [region](#output\_region) | AWS region |
<!-- END_TF_DOCS -->