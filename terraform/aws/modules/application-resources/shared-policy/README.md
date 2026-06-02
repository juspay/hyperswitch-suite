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
<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Map of IAM policies to create | <pre>map(object({<br/>    name        = string<br/>    description = string<br/>    path        = string<br/>    policy      = string<br/>    tags        = optional(map(string), {})<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_policy_arns"></a> [policy\_arns](#output\_policy\_arns) | Map of policy ARNs keyed by policy key |
| <a name="output_policy_names"></a> [policy\_names](#output\_policy\_names) | Map of policy names keyed by policy key |
<!-- END_TF_DOCS -->