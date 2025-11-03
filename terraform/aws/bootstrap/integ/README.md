# Integration Environment Bootstrap

This directory is for setting up the Terraform remote state backend (S3 + DynamoDB) for the integration environment.

## Setup Instructions

Copy the bootstrap configuration from the dev environment and update with integration-specific values:

```bash
# Copy all files from dev
cp ../dev/*.tf .

# Update the configuration
# Edit main.tf and update:
# - environment = "integ"
# - s3_bucket_name = "hyperswitch-terraform-state-integ"
# - dynamodb_table_name = "terraform-state-lock-integ"

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## What This Creates

- S3 bucket for storing Terraform state files
- DynamoDB table for state locking
- Encryption and versioning enabled
- Lifecycle policies for cost optimization

## Note

This bootstrap setup only needs to be run once per environment. After the S3 bucket and DynamoDB table are created, all other Terraform deployments in this environment will use these for remote state management.
