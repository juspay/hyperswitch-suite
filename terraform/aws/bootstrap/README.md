# Terraform Backend Bootstrap

Bootstrap infrastructure for Terraform remote state management (S3 + DynamoDB) across all environments.

## Overview

One-time setup that creates:
- S3 bucket for storing Terraform state files
- DynamoDB table for state locking
- Security policies (encryption, versioning, TLS enforcement)

## Directory Structure

```
bootstrap/
├── dev/         # Development backend (public reference with masked values)
├── integ/       # Integration backend (copy from dev, update values)
├── prod/        # Production backend (copy from dev, add KMS)
├── sandbox/     # Sandbox backend (copy from dev, update values)
└── README.md    # This file
```

## What Gets Created

| Resource | Purpose | Configuration |
|----------|---------|---------------|
| S3 Bucket | State storage | Versioning, encryption, private access |
| DynamoDB Table | State locking | PAY_PER_REQUEST billing, encryption |
| Bucket Policy | Security | Enforce TLS, prevent public access |

## Quick Start

### 1. Bootstrap Development Environment

```bash
cd bootstrap/dev

# Review and update terraform.tfvars if needed
vi terraform.tfvars

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### 2. Update Live Deployments

After bootstrap is created, configure your services to use the backend:

```bash
cd ../../live/dev/eu-central-1/squid-proxy/

# Edit backend.tf:
terraform {
  backend "s3" {
    bucket         = "hyperswitch-dev-terraform-state"
    key            = "dev/eu-central-1/squid-proxy/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "hyperswitch-dev-terraform-state-lock"
    encrypt        = true
  }
}

# Reconfigure backend
terraform init -reconfigure
```

### 3. Setup Other Environments

For integ, prod, or sandbox environments:

```bash
# Copy from dev
cd bootstrap/integ
cp ../dev/*.tf .

# Update configuration
vi main.tf
# Change: environment = "integ"
# Change: bucket name to "hyperswitch-terraform-state-integ"
# Change: DynamoDB table to "terraform-state-lock-integ"

# Deploy
terraform init
terraform apply
```

See individual environment README files for specific instructions.

## Environment Configuration

| Environment | Allow Destroy | PITR | Encryption | Use Case |
|-------------|---------------|------|------------|----------|
| dev | true | false | AES256 | Development, testing |
| integ | true | false | AES256 | Integration, UAT |
| prod | false | true | AES256/KMS | Production workloads |
| sandbox | true | false | AES256 | Experimentation |

## State File Organization

After deployment, your S3 bucket structure:

```
s3://hyperswitch-terraform-state-{env}/
├── {env}/{region}/squid-proxy/terraform.tfstate
├── {env}/{region}/envoy-proxy/terraform.tfstate
└── bootstrap/{env}/terraform.tfstate (if migrated to S3)
```

## Bootstrap State Management

### Local Backend (Default)

Bootstrap's own state is stored locally by default:
- Simple, no dependencies
- Must protect/backup manually
- Good for single-user environments

### S3 Backend (Recommended for Production)

After creating the backend, migrate bootstrap's state to S3:

```bash
cd bootstrap/prod

# Edit backend.tf to uncomment S3 backend configuration
vi backend.tf

# Migrate state
terraform init -migrate-state

# Verify
terraform plan
```

Note: Once migrated to S3, you must migrate back to local before destroying the backend.

## Security Best Practices

**Already Configured:**
- Versioning enabled
- Encryption at rest (AES256)
- Public access blocked
- TLS enforcement (HTTPS only)
- DynamoDB encryption

**Production Recommendations:**
- Use KMS encryption for S3
- Enable S3 bucket logging
- Enable MFA delete protection
- Point-in-time recovery (PITR) for DynamoDB
- Restrict IAM access to state files

## Cost Estimation

**Development/Integration:**
- S3 Storage: ~$0.023/GB/month
- DynamoDB: ~$0.00 (PAY_PER_REQUEST, minimal usage)
- Total: ~$0.50-1.00/month

**Production:**
- S3 Storage: ~$0.023/GB/month
- S3 Versioning: Variable
- DynamoDB PITR: +$0.20/GB/month
- Total: ~$1-5/month (depending on state size)

State locking operations are very cheap - DynamoDB charges per request.

## Troubleshooting

**Bucket name already exists:**
```bash
# Update terraform.tfvars with unique suffix
state_bucket_name = "hyperswitch-terraform-state-dev-YOUR-SUFFIX"
```

**Access denied:**
```bash
aws sts get-caller-identity
aws s3 ls
```

**State lock timeout:**
```bash
# If previous run crashed, force unlock
terraform force-unlock <LOCK_ID>
```

**Test state locking:**
```bash
# Terminal 1
terraform plan  # Acquires lock

# Terminal 2 (should fail)
terraform plan  # Error: state lock acquired
```

## Cleanup

WARNING: Only destroy if tearing down entire environment!

**If using local backend:**
```bash
terraform destroy
```

**If using S3 backend:**
```bash
# 1. Migrate state back to local (edit backend.tf)
terraform init -migrate-state

# 2. Destroy
terraform destroy
```

This deletes the S3 bucket, DynamoDB table, and all state history.

## Next Steps

After bootstrapping:
1. Configure all live deployments to use remote backend
2. Test state locking works
3. Set up backup/monitoring for state files
4. Document access control policies
5. Consider migrating bootstrap state to S3 (production)
