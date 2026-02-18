# Shared IAM Policy Module

Creates multiple IAM customer-managed policies from a map input. These policies can be shared across multiple IAM roles.

## Usage

```hcl
module "shared_policies" {
  source = "../../../../modules/application-resources/shared-policy"

  common_tags = {
    Project     = "hyperswitch"
    Environment = "dev"
  }

  policies = {
    s3_file_uploads = {
      name        = "hyperswitch-s3-file-uploads-policy"
      description = "Policy for file uploads S3 access"
      path        = "/"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = ["s3:PutObject", "s3:GetObject"]
            Resource = "arn:aws:s3:::my-bucket/*"
          }
        ]
      })
    },

    ses_send_email = {
      name        = "ses-send-email-policy"
      description = "Policy for sending emails via SES"
      path        = "/"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = ["ses:SendEmail", "ses:SendRawEmail"]
            Resource = "*"
          }
        ]
      })
    }
  }
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `policies` | Map of IAM policies to create | `map(object({...}))` | - |
| `common_tags` | Common tags for all resources | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `policy_arns` | Map of policy ARNs keyed by policy key |
| `policy_names` | Map of policy names keyed by policy key |

## Referencing Policies in Other Modules

```hcl
# In another module (e.g., hyperswitch-app)
data "aws_iam_policy" "s3_file_uploads" {
  name = module.shared_policies.policy_names.s3_file_uploads
}

module "eks_iam" {
  # ...
  customer_managed_policy_arns = [
    data.aws_iam_policy.s3_file_uploads.arn
  ]
}
```