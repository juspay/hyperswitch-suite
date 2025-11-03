# Production Environment Bootstrap

This directory is for setting up the Terraform remote state backend (S3 + DynamoDB) for the production environment.

## Setup Instructions

Copy the bootstrap configuration from the dev environment and update with production-specific values:

```bash
# Copy all files from dev
cp ../dev/*.tf .

# Update the configuration
# Edit main.tf and update:
# - environment = "prod"
# - s3_bucket_name = "hyperswitch-terraform-state-prod"
# - dynamodb_table_name = "terraform-state-lock-prod"
# - enable_kms_encryption = true (recommended for production)

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## What This Creates

- S3 bucket for storing Terraform state files
- DynamoDB table for state locking
- KMS encryption (recommended)
- Versioning and lifecycle policies
- Enhanced security configurations

## Production Considerations

- Enable KMS encryption for state files
- Configure bucket policies for restricted access
- Enable MFA delete for state bucket
- Set up cross-region replication (optional)
- Configure CloudTrail logging for audit

## Note

This bootstrap setup only needs to be run once per environment. After the S3 bucket and DynamoDB table are created, all other Terraform deployments in this environment will use these for remote state management.
