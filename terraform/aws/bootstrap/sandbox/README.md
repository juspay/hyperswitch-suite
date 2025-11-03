# Sandbox Environment Bootstrap

This directory is for setting up the Terraform remote state backend (S3 + DynamoDB) for the sandbox environment.

## Setup Instructions

Copy the bootstrap configuration from the dev environment and update with sandbox-specific values:

```bash
# Copy all files from dev
cp ../dev/*.tf .

# Update the configuration
# Edit main.tf and update:
# - environment = "sandbox"
# - s3_bucket_name = "hyperswitch-terraform-state-sandbox"
# - dynamodb_table_name = "terraform-state-lock-sandbox"

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## What This Creates

- S3 bucket for storing Terraform state files
- DynamoDB table for state locking
- Basic encryption and versioning
- Lifecycle policies for cost optimization

## Sandbox Characteristics

- Minimal configuration for cost optimization
- Can be destroyed and recreated as needed
- Suitable for experimentation and testing
- No production-grade security requirements

## Note

This bootstrap setup only needs to be run once per environment. After the S3 bucket and DynamoDB table are created, all other Terraform deployments in this environment will use these for remote state management.

For sandbox environments, you may also choose to use local state instead of remote state to reduce costs and complexity.
