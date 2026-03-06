# ArgoCD IAM Role Module

This Terraform module creates an IAM role for ArgoCD with cross-account deployment capabilities.

## Features

- Creates an IAM role with configurable trust policies
- Supports self-assumption for role chaining
- Integrates with EKS OIDC provider for service account authentication
- Enables cross-account role assumption for multi-account deployments
- Configurable service accounts and namespaces

## Usage

```hcl
module "argocd_role" {
  source = "../../modules/application-resources/argocd"

  # Environment & Project
  region       = "eu-central-1"
  environment  = "dev"
  project_name = "hyperswitch"

  # IAM Role Configuration
  role_name               = "argocd-management-role"  # Optional: defaults to {project}-{env}-argocd-management-role
  role_description        = "IAM role for ArgoCD to manage deployments"
  max_session_duration    = 3600
  
  # Trust Policy Configuration
  aws_account_id       = "701342709052"
  self_assume_enabled  = true
  oidc_provider_arn    = "arn:aws:iam::701342709052:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/D8874FEADD8373D93A7323D3772B1BB1"
  
  # ArgoCD Configuration
  argocd_namespace = "argocd"
  argocd_service_accounts = [
    "argocd-application-controller",
    "argocd-applicationset-controller",
    "argocd-server"
  ]
  
  # Cross-Account Role Assumption
  cross_account_roles = [
    "arn:aws:iam::225681119357:role/dev-hyperswitch-argocd-cross-account",
    "arn:aws:iam::701342709052:role/sbx-hyperswitch-argocd-cross-account"
  ]
  create_assume_role_policy = true
  
  # Additional Policies (Optional)
  additional_policy_arns = [
    # Add any additional managed policy ARNs here
  ]

  # Tags
  common_tags = {
    Team        = "Platform"
    CostCenter  = "Engineering"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region | `string` | n/a | yes |
| environment | Environment name (e.g., sandbox, dev, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming and tagging | `string` | n/a | yes |
| role_name | Name of the ArgoCD management IAM role | `string` | `null` | no |
| role_description | Description for the ArgoCD management IAM role | `string` | `"IAM role for ArgoCD to manage cross-account deployments"` | no |
| role_path | Path for the IAM role | `string` | `"/"` | no |
| max_session_duration | Maximum session duration in seconds | `number` | `3600` | no |
| aws_account_id | AWS Account ID where the role is created | `string` | n/a | yes |
| self_assume_enabled | Enable self-assumption of the role | `bool` | `true` | no |
| oidc_provider_arn | ARN of the EKS OIDC provider | `string` | n/a | yes |
| argocd_namespace | Kubernetes namespace where ArgoCD is deployed | `string` | `"argocd"` | no |
| argocd_service_accounts | List of ArgoCD service accounts that can assume this role | `list(string)` | See variables.tf | no |
| oidc_audience | Audience for OIDC token validation | `string` | `"sts.amazonaws.com"` | no |
| cross_account_roles | List of cross-account role ARNs that ArgoCD can assume | `list(string)` | `[]` | no |
| create_assume_role_policy | Whether to create and attach the assume role policy | `bool` | `true` | no |
| additional_policy_arns | Additional policy ARNs to attach to the role | `list(string)` | `[]` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_name | Name of the ArgoCD management IAM role |
| role_arn | ARN of the ArgoCD management IAM role |
| role_id | ID of the ArgoCD management IAM role |
| role_unique_id | Unique ID of the ArgoCD management IAM role |
| oidc_provider_url | OIDC provider URL extracted from the ARN |
| service_accounts | List of service accounts that can assume the role |

## Trust Policy

The module creates a trust policy with two statements:

### 1. Self Role Assumption (Optional)
Allows the role to assume itself, useful for role chaining:

```json
{
    "Sid": "ExplicitSelfRoleAssumption",
    "Effect": "Allow",
    "Principal": {
        "AWS": "*"
    },
    "Action": "sts:AssumeRole",
    "Condition": {
        "ArnLike": {
            "aws:PrincipalArn": "arn:aws:iam::{account-id}:role/{role-name}"
        }
    }
}
```

### 2. Service Account Assumption
Allows ArgoCD service accounts to assume the role via OIDC:

```json
{
    "Sid": "ServiceAccountRoleAssumption",
    "Effect": "Allow",
    "Principal": {
        "Federated": "arn:aws:iam::{account-id}:oidc-provider/{oidc-url}"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
        "StringEquals": {
            "{oidc-url}:sub": [
                "system:serviceaccount:argocd:argocd-application-controller",
                "system:serviceaccount:argocd:argocd-applicationset-controller",
                "system:serviceaccount:argocd:argocd-server"
            ],
            "{oidc-url}:aud": "sts.amazonaws.com"
        }
    }
}
```

## Permissions Policy

The module attaches an inline policy allowing the role to assume specified cross-account roles:

```json
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": [
            "arn:aws:iam::225681119357:role/dev-hyperswitch-argocd-cross-account",
            "arn:aws:iam::701342709052:role/sbx-hyperswitch-argocd-cross-account"
        ]
    }
}
```

## Notes

- The OIDC provider must be created and associated with your EKS cluster before using this module
- Ensure the cross-account roles trust this management role in their trust policies
- Default service accounts include the three main ArgoCD components; customize as needed
- The role name defaults to `{project_name}-{environment}-argocd-management-role` if not specified
