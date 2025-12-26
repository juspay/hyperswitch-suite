# ArgoCD Cross-Cluster Management IAM Setup

This document outlines the steps to configure IAM roles and policies for ArgoCD to manage multiple EKS clusters across AWS accounts using IRSA (IAM Roles for Service Accounts).

## Overview

This setup enables ArgoCD deployed in one AWS account to manage resources in other AWS accounts/clusters by using IAM role assumption with proper trust policies.

## Architecture

- **Source Cluster**: EKS cluster where ArgoCD is deployed
- **Destination Cluster(s)**: EKS clusters that ArgoCD will manage
- **IAM Role**: `argocd-management-role` with permissions to assume cross-account roles

---

## Step 1: Create the ArgoCD Management Role

Create an IAM role named `argocd-management-role` in the AWS account where ArgoCD is deployed.

### 1.1 IAM Policy

This policy allows the role to assume roles in destination AWS accounts.

**Policy Name**: `argocd-cross-account-assume-policy`

```json
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Action": "sts:AssumeRole",
    "Resource": [
      "arn:aws:iam::{destination_aws_account_1}:role/dev-hyperswitch-argocd-cross-account",
      "arn:aws:iam::{destination_aws_account_2}:role/dev-hyperswitch-argocd-cross-account"
    ]
  }
}
```

**Note**: Add more resource ARNs for additional destination clusters/accounts.

### 1.2 Trust Policy

This trust policy allows the role to be assumed by:
1. Itself (for self-assumption)
2. ArgoCD service accounts via OIDC (IRSA)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ExplicitSelfRoleAssumption",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ArnLike": {
          "aws:PrincipalArn": "arn:aws:iam::{argocd_aws_account}:role/argocd-management-role"
        }
      }
    },
    {
      "Sid": "ServiceAccountRoleAssumption",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::{argocd_aws_account}:oidc-provider/{oidc_provider_url}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "{oidc_provider_url}:sub": [
            "system:serviceaccount:argocd:argocd-application-controller",
            "system:serviceaccount:argocd:argocd-applicationset-controller",
            "system:serviceaccount:argocd:argocd-server"
          ],
          "{oidc_provider_url}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

### 1.3 Variables to Replace

| Variable | Description | Example |
|----------|-------------|---------|
| `{argocd_aws_account}` | AWS account ID where ArgoCD is deployed | `123456789012` |
| `{destination_aws_account_1}` | AWS account ID of destination cluster | `987654321098` |
| `{oidc_provider_url}` | OIDC provider URL for the ArgoCD EKS cluster (without `https://`) | `oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE` |

---

## Step 2: Annotate ArgoCD Service Accounts

Add the IAM role annotation to the following ArgoCD service accounts to enable IRSA.

### Service Accounts to Annotate

1. `argocd-application-controller`
2. `argocd-applicationset-controller`
3. `argocd-server`

### Annotation Format

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <service-account-name>
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::{argocd_aws_account}:role/argocd-management-role
```

### Apply Annotations

You can apply these annotations using `kubectl`:

```bash
# Annotate argocd-application-controller
kubectl annotate serviceaccount argocd-application-controller \
  -n argocd \
  eks.amazonaws.com/role-arn=arn:aws:iam::{argocd_aws_account}:role/argocd-management-role \
  --overwrite

# Annotate argocd-applicationset-controller
kubectl annotate serviceaccount argocd-applicationset-controller \
  -n argocd \
  eks.amazonaws.com/role-arn=arn:aws:iam::{argocd_aws_account}:role/argocd-management-role \
  --overwrite

# Annotate argocd-server
kubectl annotate serviceaccount argocd-server \
  -n argocd \
  eks.amazonaws.com/role-arn=arn:aws:iam::{argocd_aws_account}:role/argocd-management-role \
  --overwrite
```

---

## Step 3: Create Cross-Account Role in Destination Accounts
(Handled by the eks terraform, no need to add anything manual)
In each destination AWS account, create a role that ArgoCD can assume.

### Role Name

`dev-hyperswitch-argocd-cross-account` (or customize as needed)

### Trust Policy for Destination Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::{argocd_aws_account}:role/argocd-management-role"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Permissions Policy for Destination Role

Attach appropriate EKS and Kubernetes management permissions. Example:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
```

**Note**: Adjust permissions based on your security requirements.

---

## Step 4: Restart ArgoCD Pods

After annotating the service accounts, restart the ArgoCD pods to pick up the new IAM role:

```bash
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart statefulset argocd-application-controller -n argocd
kubectl rollout restart deployment argocd-applicationset-controller -n argocd
```

---

## Step 5: Verify the Setup

### 5.1 Verify Service Account Annotations

```bash
kubectl describe sa argocd-application-controller -n argocd
kubectl describe sa argocd-applicationset-controller -n argocd
kubectl describe sa argocd-server -n argocd
```

Look for the `eks.amazonaws.com/role-arn` annotation.

### 5.2 Verify IAM Role Assumption

Check the pods to ensure they can assume the IAM role:

```bash
kubectl exec -it -n argocd deployment/argocd-server -- env | grep AWS
```

You should see environment variables like:
- `AWS_ROLE_ARN`
- `AWS_WEB_IDENTITY_TOKEN_FILE`


---

## How to Get OIDC Provider URL

To find your EKS cluster's OIDC provider URL:

```bash
aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text
```

Remove the `https://` prefix when using it in IAM policies.

**Example**:
- Full URL: `https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE`
- Use in policy: `oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE`

---

## Troubleshooting

### Issue: Pods cannot assume role

**Check**:
1. Verify service account annotations are correct
2. Ensure OIDC provider is associated with the EKS cluster
3. Verify trust policy includes correct OIDC provider URL
4. Restart pods after applying annotations

### Issue: Access denied when assuming cross-account role

**Check**:
1. Verify the destination role's trust policy allows the source role
2. Ensure the source role has `sts:AssumeRole` permission for the destination role ARN
3. Check that role ARNs are correct

### Issue: OIDC provider not found

**Solution**:
Create an OIDC provider for your EKS cluster:

```bash
eksctl utils associate-iam-oidc-provider \
  --cluster <cluster-name> \
  --approve
```

---

## Security Best Practices

1. **Principle of Least Privilege**: Grant only the minimum permissions required
2. **Use Specific ARNs**: Avoid wildcards in resource ARNs where possible
3. **Regular Audits**: Periodically review IAM roles and their usage
4. **Session Duration**: Configure appropriate session durations for assumed roles
5. **Monitoring**: Enable CloudTrail logging for role assumption events

---

## Additional Resources

- [AWS IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [ArgoCD Multi-Cluster Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#clusters)
- [AWS STS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)

---

## Summary

This setup enables ArgoCD to manage multiple EKS clusters across AWS accounts by:

1. Creating an IAM role (`argocd-management-role`) in the ArgoCD account
2. Configuring IRSA for ArgoCD service accounts
3. Allowing the role to assume cross-account roles in destination accounts
4. Setting up proper trust relationships between accounts

After completing these steps, ArgoCD can deploy and manage applications across multiple clusters securely using AWS IAM roles.
