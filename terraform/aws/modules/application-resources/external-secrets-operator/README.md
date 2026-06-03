# External Secrets Operator IAM Role Module

This Terraform module creates an IAM role for External Secrets Operator to access AWS Secrets Manager. The role uses OIDC-based authentication with EKS clusters, allowing Kubernetes service accounts to assume the role via IRSA (IAM Roles for Service Accounts).

## Features

- Creates an IAM role with OIDC trust policy for EKS clusters
- Grants Secrets Manager read permissions (`GetSecretValue` and `DescribeSecret`)
- Supports multiple EKS clusters and service accounts
- Configurable role name, description, and session duration
- Supports additional policy attachments

## Usage

```hcl
module "external_secrets_operator" {
  source = "../../modules/application-resources/external-secrets-operator"

  # Project & Environment
  project_name = "hyperswitch"
  environment  = "dev"
  region       = "eu-central-1"

  # AWS Account
  aws_account_id = "701342709052"

  # Cluster and Service Account Configuration
  cluster_service_accounts = {
    "dev-eks-cluster" = [
      {
        namespace = "external-secrets-operator"
        name      = "external-secrets-sa"
      }
    ]
  }

  # Optional: Custom role name
  role_name = "custom-external-secrets-role"

  # Optional: Additional tags
  common_tags = {
    Team = "platform"
    Cost = "infrastructure"
  }
}
```

## IAM Policy

The module creates an inline IAM policy that grants the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SecretsManagerAccess",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": [
                "arn:aws:secretsmanager:<region>:<account-id>:secret:*"
            ]
        }
    ]
}
```

## Trust Policy

The module creates a trust policy that allows EKS service accounts to assume the role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<account-id>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<oidc-id>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.<region>.amazonaws.com/id/<oidc-id>:sub": "system:serviceaccount:<namespace>:<service-account>",
                    "oidc.eks.<region>.amazonaws.com/id/<oidc-id>:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Project name for resource naming and tagging | `string` | n/a | yes |
| environment | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| region | AWS region | `string` | n/a | yes |
| aws_account_id | AWS Account ID where the role is created | `string` | n/a | yes |
| cluster_service_accounts | Map of cluster names to service accounts | `map(list(object))` | `{}` | yes |
| role_name | Custom name for the IAM role | `string` | `null` | no |
| role_description | Description for the IAM role | `string` | `"IAM role for External Secrets Operator to access AWS Secrets Manager"` | no |
| role_path | Path for the IAM role | `string` | `"/"` | no |
| max_session_duration | Maximum session duration in seconds | `number` | `3600` | no |
| external_secrets_namespace | Kubernetes namespace for External Secrets Operator | `string` | `"external-secrets-operator"` | no |
| external_secrets_service_account | Service account name | `string` | `"external-secrets-sa"` | no |
| oidc_audience | Audience for OIDC token validation | `string` | `"sts.amazonaws.com"` | no |
| additional_assume_role_statements | Additional IAM policy statements for assume role policy | `list(any)` | `[]` | no |
| additional_policy_arns | Additional policy ARNs to attach | `list(string)` | `[]` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_name | Name of the External Secrets Operator IAM role |
| role_arn | ARN of the External Secrets Operator IAM role |
| role_id | ID of the External Secrets Operator IAM role |
| role_unique_id | Unique ID of the External Secrets Operator IAM role |
| oidc_provider_urls | Map of cluster names to their OIDC provider URLs |
| cluster_service_accounts | Map of cluster names to their service account subjects |
| secrets_manager_policy_json | JSON of the Secrets Manager access policy |

## Kubernetes Service Account Annotation

After creating the IAM role, annotate the Kubernetes service account with the role ARN:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: external-secrets-operator
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/<role-name>
```

Or use Terraform with the Kubernetes provider:

```hcl
resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets-operator"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_operator.role_arn
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## License

See the main project LICENSE file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.external_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.secrets_manager_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_openid_connect_provider.oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_openid_connect_provider) | data source |
| [aws_iam_policy_document.secrets_manager_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_assume_role_statements"></a> [additional\_assume\_role\_statements](#input\_additional\_assume\_role\_statements) | Additional IAM policy statements to add to the role's assume role policy | `list(any)` | `[]` | no |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | Additional policy ARNs to attach to the External Secrets Operator role | `list(string)` | `[]` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID where the role is created | `string` | n/a | yes |
| <a name="input_cluster_service_accounts"></a> [cluster\_service\_accounts](#input\_cluster\_service\_accounts) | Map of cluster names to service accounts that can assume this role. Each service account must have 'namespace' and 'name' attributes. | <pre>map(list(object({<br/>    namespace = string<br/>    name      = string<br/>  })))</pre> | `{}` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| <a name="input_external_secrets_namespace"></a> [external\_secrets\_namespace](#input\_external\_secrets\_namespace) | Kubernetes namespace where External Secrets Operator is deployed | `string` | `"external-secrets-operator"` | no |
| <a name="input_external_secrets_service_account"></a> [external\_secrets\_service\_account](#input\_external\_secrets\_service\_account) | Service account name for External Secrets Operator | `string` | `"external-secrets-sa"` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds for the role | `number` | `3600` | no |
| <a name="input_oidc_audience"></a> [oidc\_audience](#input\_oidc\_audience) | Audience for OIDC token validation | `string` | `"sts.amazonaws.com"` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name for resource naming and tagging | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | n/a | yes |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description for the External Secrets Operator IAM role | `string` | `"IAM role for External Secrets Operator to access AWS Secrets Manager"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the External Secrets Operator IAM role. If null, defaults to {project}-{env}-external-secrets-role | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path for the IAM role | `string` | `"/"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_service_accounts"></a> [cluster\_service\_accounts](#output\_cluster\_service\_accounts) | Map of cluster names to their service account subjects |
| <a name="output_oidc_provider_urls"></a> [oidc\_provider\_urls](#output\_oidc\_provider\_urls) | Map of cluster names to their OIDC provider URLs |
| <a name="output_region"></a> [region](#output\_region) | AWS region where resources are created |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the External Secrets Operator IAM role |
| <a name="output_role_id"></a> [role\_id](#output\_role\_id) | ID of the External Secrets Operator IAM role |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the External Secrets Operator IAM role |
| <a name="output_role_unique_id"></a> [role\_unique\_id](#output\_role\_unique\_id) | Unique ID of the External Secrets Operator IAM role |
| <a name="output_secrets_manager_policy_json"></a> [secrets\_manager\_policy\_json](#output\_secrets\_manager\_policy\_json) | JSON of the Secrets Manager access policy |
<!-- END_TF_DOCS -->