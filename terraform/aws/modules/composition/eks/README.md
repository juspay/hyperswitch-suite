<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ebs_csi_irsa"></a> [ebs\_csi\_irsa](#module\_ebs\_csi\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.44.0 |
| <a name="module_efs_csi_irsa"></a> [efs\_csi\_irsa](#module\_efs\_csi\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | 5.44.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 20.0 |

## Resources

| Name | Type |
|------|------|
| [aws_eks_addon.after_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.before_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_node_group.custom_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_policy.cluster_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.node_group_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cross_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cross_account_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cross_account_policy_arns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_template.custom_node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_launch_template.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ssm_parameter.node_group_private_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [tls_private_key.node_group](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ssm_parameter.eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_access_entries"></a> [cluster\_access\_entries](#input\_cluster\_access\_entries) | Map of IAM principals to grant access to the EKS cluster | `any` | `{}` | no |
| <a name="input_cluster_custom_policy_json"></a> [cluster\_custom\_policy\_json](#input\_cluster\_custom\_policy\_json) | Custom IAM policy JSON for cluster role (additional permissions). Set to null to skip. | `string` | `null` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Enable private API server endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Enable public API server endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#input\_cluster\_iam\_role\_arn) | Existing IAM role ARN for EKS cluster (required if create\_cluster\_iam\_role = false) | `string` | `null` | no |
| <a name="input_cluster_iam_role_assume_role_policy"></a> [cluster\_iam\_role\_assume\_role\_policy](#input\_cluster\_iam\_role\_assume\_role\_policy) | Assume role policy JSON for EKS cluster IAM role. MUST be provided from live layer. | `string` | n/a | yes |
| <a name="input_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#input\_cluster\_iam\_role\_name) | Custom name for the EKS cluster IAM role (auto-generated if null) | `string` | `null` | no |
| <a name="input_cluster_iam_role_policies"></a> [cluster\_iam\_role\_policies](#input\_cluster\_iam\_role\_policies) | Map of IAM policy ARNs to attach to the cluster IAM role | `map(string)` | `{}` | no |
| <a name="input_cluster_name_version"></a> [cluster\_name\_version](#input\_cluster\_name\_version) | Version identifier for the EKS cluster name | `string` | `"v1"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.34"` | no |
| <a name="input_control_plane_subnet_ids"></a> [control\_plane\_subnet\_ids](#input\_control\_plane\_subnet\_ids) | Subnet IDs for EKS control plane (if different from subnet\_ids) | `list(string)` | `null` | no |
| <a name="input_create_cluster_iam_role"></a> [create\_cluster\_iam\_role](#input\_create\_cluster\_iam\_role) | Whether to create a custom IAM role for the EKS cluster. Set to false if using existing role. | `bool` | `true` | no |
| <a name="input_create_cross_account_role"></a> [create\_cross\_account\_role](#input\_create\_cross\_account\_role) | Whether to create IAM role for cross-account access | `bool` | `false` | no |
| <a name="input_create_node_group_iam_role"></a> [create\_node\_group\_iam\_role](#input\_create\_node\_group\_iam\_role) | Whether to create a custom IAM role for node groups. Set to false if using existing role. | `bool` | `true` | no |
| <a name="input_create_ssh_key"></a> [create\_ssh\_key](#input\_create\_ssh\_key) | Whether to create a new SSH key pair for node groups | `bool` | `false` | no |
| <a name="input_cross_account_assume_role_policy"></a> [cross\_account\_assume\_role\_policy](#input\_cross\_account\_assume\_role\_policy) | Assume role policy JSON for cross-account role. MUST be provided if create\_cross\_account\_role = true. | `string` | `null` | no |
| <a name="input_cross_account_policy_arns"></a> [cross\_account\_policy\_arns](#input\_cross\_account\_policy\_arns) | List of IAM policy ARNs to attach to cross-account role (alternative to policy JSON) | `list(string)` | `[]` | no |
| <a name="input_cross_account_policy_json"></a> [cross\_account\_policy\_json](#input\_cross\_account\_policy\_json) | IAM policy JSON for cross-account role. MUST be provided if create\_cross\_account\_role = true. | `string` | `null` | no |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Custom name for cross-account role (auto-generated if null) | `string` | `null` | no |
| <a name="input_custom_userdata_template_path"></a> [custom\_userdata\_template\_path](#input\_custom\_userdata\_template\_path) | Path to custom user data template file. Uses default bootstrap template if null | `string` | `null` | no |
| <a name="input_default_ami_id"></a> [default\_ami\_id](#input\_default\_ami\_id) | Default AMI ID for EKS nodes. If null, the latest EKS-optimized AMI will be used via data source | `string` | `null` | no |
| <a name="input_default_block_device_mappings"></a> [default\_block\_device\_mappings](#input\_default\_block\_device\_mappings) | Default block device mappings for launch templates | <pre>list(object({<br/>    device_name           = string<br/>    volume_size           = number<br/>    volume_type           = string<br/>    delete_on_termination = bool<br/>    encrypted             = bool<br/>    kms_key_id            = optional(string)<br/>    iops                  = optional(number)<br/>    throughput            = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "delete_on_termination": true,<br/>    "device_name": "/dev/xvda",<br/>    "encrypted": true,<br/>    "iops": null,<br/>    "kms_key_id": null,<br/>    "throughput": null,<br/>    "volume_size": 20,<br/>    "volume_type": "gp3"<br/>  }<br/>]</pre> | no |
| <a name="input_default_metadata_options"></a> [default\_metadata\_options](#input\_default\_metadata\_options) | Default metadata options for launch templates (IMDSv2) | <pre>object({<br/>    http_endpoint               = optional(string, "enabled")<br/>    http_tokens                 = optional(string, "required")<br/>    http_put_response_hop_limit = optional(number, 2)<br/>    instance_metadata_tags      = optional(string, "enabled")<br/>  })</pre> | `{}` | no |
| <a name="input_eks_addons"></a> [eks\_addons](#input\_eks\_addons) | EKS addons configuration - map keyed by addon name | <pre>map(object({<br/>    addon_version        = string<br/>    service_account_role = optional(string) # "cluster_autoscaler", "ebs_csi", or full ARN<br/>  }))</pre> | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available | `list(string)` | `[]` | no |
| <a name="input_node_group_custom_policy_json"></a> [node\_group\_custom\_policy\_json](#input\_node\_group\_custom\_policy\_json) | Custom IAM policy JSON for node group (e.g., observability). Set to null to skip. | `string` | `null` | no |
| <a name="input_node_group_iam_role_arn"></a> [node\_group\_iam\_role\_arn](#input\_node\_group\_iam\_role\_arn) | Existing IAM role ARN for node groups (required if create\_node\_group\_iam\_role = false) | `string` | `null` | no |
| <a name="input_node_group_iam_role_assume_role_policy"></a> [node\_group\_iam\_role\_assume\_role\_policy](#input\_node\_group\_iam\_role\_assume\_role\_policy) | Assume role policy JSON for node group IAM role. MUST be provided from live layer. | `string` | n/a | yes |
| <a name="input_node_group_iam_role_name"></a> [node\_group\_iam\_role\_name](#input\_node\_group\_iam\_role\_name) | Custom name for the node group IAM role (auto-generated if null) | `string` | `null` | no |
| <a name="input_node_group_iam_role_policies"></a> [node\_group\_iam\_role\_policies](#input\_node\_group\_iam\_role\_policies) | Map of IAM policy ARNs to attach to the node group IAM role | `map(string)` | `{}` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | EKS managed node groups configuration | `any` | `{}` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"eu-central-1"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | SSH key pair name. Used directly if create\_ssh\_key=false. Used as name for new key if create\_ssh\_key=true. Auto-generated if null. | `string` | `null` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public key material for creating SSH key pair. If not provided when create\_ssh\_key=true, a new key will be auto-generated and stored in SSM. | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the cluster will be created | `string` | n/a | yes |
| <a name="input_vpn_cidr_blocks"></a> [vpn\_cidr\_blocks](#input\_vpn\_cidr\_blocks) | CIDR blocks for VPN access to EKS cluster (e.g., ['10.8.0.0/16']) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN for the EKS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The ID of the EKS cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster |
| <a name="output_cluster_name_version"></a> [cluster\_name\_version](#output\_cluster\_name\_version) | The version identifier for the EKS cluster name |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster |
| <a name="output_cluster_service_cidr"></a> [cluster\_service\_cidr](#output\_cluster\_service\_cidr) | The CIDR block where Kubernetes pod and service IP addresses are assigned from |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The Kubernetes version for the cluster |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | IAM role ARN for cross-account access (ArgoCD, Atlantis, etc.) |
| <a name="output_cross_account_role_name"></a> [cross\_account\_role\_name](#output\_cross\_account\_role\_name) | IAM role name for cross-account access |
| <a name="output_ebs_csi_iam_role_arn"></a> [ebs\_csi\_iam\_role\_arn](#output\_ebs\_csi\_iam\_role\_arn) | IAM role ARN for EBS CSI Driver |
| <a name="output_efs_csi_iam_role_arn"></a> [efs\_csi\_iam\_role\_arn](#output\_efs\_csi\_iam\_role\_arn) | IAM role ARN for EFS CSI Driver |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | Map of attribute maps for all EKS managed node groups created |
| <a name="output_eks_managed_node_groups_iam_role_arn"></a> [eks\_managed\_node\_groups\_iam\_role\_arn](#output\_eks\_managed\_node\_groups\_iam\_role\_arn) | IAM role ARN for EKS managed node groups |
| <a name="output_eks_managed_node_groups_iam_role_name"></a> [eks\_managed\_node\_groups\_iam\_role\_name](#output\_eks\_managed\_node\_groups\_iam\_role\_name) | IAM role name for EKS managed node groups |
| <a name="output_node_group_security_group_ids"></a> [node\_group\_security\_group\_ids](#output\_node\_group\_security\_group\_ids) | Map of node group names to their security group IDs |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | ID of the node shared security group |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | The ARN of the OIDC Provider |
<!-- END_TF_DOCS -->