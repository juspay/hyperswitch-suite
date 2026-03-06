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
