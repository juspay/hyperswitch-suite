# Terraform Backend Bootstrap

This directory contains the bootstrap infrastructure that creates the S3 bucket and DynamoDB table required for Terraform remote state management across all environments.

## Overview

The bootstrap layer is a **one-time setup** that creates:
- **S3 bucket** for storing Terraform state files
- **DynamoDB table** for state locking (prevents race conditions)
- **Security policies** (encryption, versioning, TLS enforcement)

## Architecture

```
terraform/aws/
├── bootstrap/
│   ├── dev/          # Development backend infrastructure
│   ├── integ/        # Integration backend infrastructure
│   ├── prod/         # Production backend infrastructure
│   └── README.md     # This file
├── modules/
│   ├── base/
│   │   ├── s3-bucket/       # Reusable S3 module
│   │   └── dynamodb-table/  # Reusable DynamoDB module
│   └── composition/
│       └── terraform-backend/  # Combines S3 + DynamoDB + policies
└── live/
    └── {env}/{region}/{service}/  # Uses the backend created here
```

## What Gets Created

For each environment (dev/integ/prod), the bootstrap creates:

| Resource | Purpose | Configuration |
|----------|---------|---------------|
| **S3 Bucket** | State storage | Versioning, encryption, private access |
| **DynamoDB Table** | State locking | PAY_PER_REQUEST billing, encryption |
| **Bucket Policy** | Security | Enforce TLS, prevent public access |

### Example: Dev Environment

- S3 Bucket: `hyperswitch-dev-terraform-state`
- DynamoDB Table: `hyperswitch-dev-terraform-state-lock`
- Region: `eu-central-1`

## Quick Start

### 1. Bootstrap Development Environment

```bash
cd bootstrap/dev

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the backend infrastructure
terraform apply

# Output will show bucket name, DynamoDB table, and next steps
```

### 2. Update Your Live Deployments

After bootstrap is created, update your service deployments to use the new backend:

```bash
cd ../../live/dev/eu-central-1/squid-proxy/

# Edit backend.tf to add the dynamodb_table parameter:
terraform {
  backend "s3" {
    bucket         = "hyperswitch-dev-terraform-state"
    key            = "dev/eu-central-1/squid-proxy/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "hyperswitch-dev-terraform-state-lock"  # ← Add this
    encrypt        = true
  }
}

# Reconfigure backend to use DynamoDB locking
terraform init -reconfigure
```

Repeat for all services (envoy-proxy, etc.)

### 3. Test State Locking

Open two terminals and verify locking works:

```bash
# Terminal 1
cd live/dev/eu-central-1/squid-proxy
terraform plan  # This acquires the lock

# Terminal 2 (while Terminal 1 is still running)
terraform plan  # This should fail with: "Error acquiring the state lock"
```

If you see the lock error in Terminal 2, **state locking is working!** 🎉

## Environment-Specific Setup

### Development (dev)

```bash
cd bootstrap/dev
terraform init
terraform apply
```

**Settings:**
- `allow_destroy = true` (can delete easily)
- `enable_dynamodb_pitr = false` (not critical for dev)
- Encryption: AES256

### Integration (integ)

```bash
cd bootstrap/integ
terraform init
terraform apply
```

**Settings:**
- `allow_destroy = true` (can recreate if needed)
- `enable_dynamodb_pitr = false`
- Encryption: AES256

### Production (prod)

```bash
cd bootstrap/prod
terraform init
terraform apply
```

**Settings:**
- `allow_destroy = false` ⚠️ (prevents accidental deletion)
- `enable_dynamodb_pitr = true` ⚠️ (point-in-time recovery enabled)
- Encryption: AES256 (consider KMS for production)

## Customization via terraform.tfvars

Each environment has a `terraform.tfvars` file for customization:

```hcl
# Example: bootstrap/dev/terraform.tfvars

region              = "eu-central-1"
state_bucket_name   = "hyperswitch-dev-terraform-state"
dynamodb_table_name = "hyperswitch-dev-terraform-state-lock"

# Optional: Add custom tags
tags = {
  Team        = "DevOps"
  CostCenter  = "Engineering"
  Compliance  = "SOC2"
}
```

## State File Organization

After deploying bootstrap and migrating your services, your S3 bucket structure will look like:

```
s3://hyperswitch-dev-terraform-state/
├── dev/
│   └── eu-central-1/
│       ├── squid-proxy/
│       │   └── terraform.tfstate
│       └── envoy-proxy/
│           └── terraform.tfstate
└── bootstrap/
    └── dev/
        └── terraform.tfstate  # (only if migrated to S3)
```

## Bootstrap State Management

### Option 1: Local Backend (Default)

By default, the bootstrap's own state is stored **locally** in each environment directory:

```
bootstrap/dev/terraform.tfstate  # Local file
```

**Pros:**
- Simple, no dependencies
- State exists before S3 bucket

**Cons:**
- Must protect/backup manually
- Team coordination required

### Option 2: Self-Referencing S3 Backend (Recommended for Production)

After creating the backend infrastructure, you can migrate the bootstrap's own state to S3:

#### Migration Steps

1. **Edit `backend.tf`** in your environment (e.g., `bootstrap/dev/backend.tf`):

```hcl
# Comment out local backend:
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# Uncomment S3 backend:
terraform {
  backend "s3" {
    bucket         = "hyperswitch-dev-terraform-state"
    key            = "bootstrap/dev/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "hyperswitch-dev-terraform-state-lock"
    encrypt        = true
  }
}
```

2. **Migrate state**:

```bash
cd bootstrap/dev
terraform init -migrate-state
# Type: yes
```

3. **Verify migration**:

```bash
aws s3 ls s3://hyperswitch-dev-terraform-state/bootstrap/dev/
# Should show: terraform.tfstate

terraform plan
# Should work without errors
```

4. **Cleanup local file** (optional):

```bash
# Backup first!
cp terraform.tfstate terraform.tfstate.backup
rm terraform.tfstate
```

#### Benefits of Self-Referencing Backend

- ✅ Centralized state management
- ✅ State locking (prevents concurrent modifications)
- ✅ Versioning and backup via S3
- ✅ Team collaboration
- ✅ Consistent with other infrastructure

#### Important Notes

⚠️ **Once migrated to S3, you cannot destroy the S3 bucket without first migrating state back to local.**

To rollback (migrate back to local):
```bash
# 1. Edit backend.tf - uncomment local, comment S3
# 2. Run migration
terraform init -migrate-state
# 3. Type: yes
```

## Security Best Practices

### S3 Bucket Security

✅ **Already Configured:**
- Versioning enabled (track state history)
- Encryption at rest (AES256)
- Public access blocked
- TLS enforcement (HTTPS only)

🔒 **Additional Recommendations for Production:**
- Consider using KMS encryption instead of AES256
- Enable S3 bucket logging
- Set up lifecycle policies for old versions
- Enable MFA delete protection

### DynamoDB Table Security

✅ **Already Configured:**
- Encryption at rest
- PAY_PER_REQUEST billing (no provisioned capacity to manage)

🔒 **Additional Recommendations for Production:**
- Point-in-time recovery enabled (prod already configured)
- Consider using customer-managed KMS keys

### Access Control

Ensure your IAM roles/users have appropriate permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::hyperswitch-*-terraform-state/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::hyperswitch-*-terraform-state"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/hyperswitch-*-terraform-state-lock"
    }
  ]
}
```

## Troubleshooting

### Bucket Name Already Exists

**Error:**
```
Error creating S3 Bucket: BucketAlreadyExists
```

**Solution:** S3 bucket names are globally unique. Update `terraform.tfvars`:

```hcl
state_bucket_name = "hyperswitch-dev-terraform-state-YOUR-UNIQUE-SUFFIX"
```

### Access Denied

**Check AWS credentials:**

```bash
aws sts get-caller-identity
aws s3 ls  # Test basic S3 access
```

### State Lock Timeout

**If you see:**
```
Error acquiring the state lock
```

**Possible causes:**
1. Another user is running Terraform (wait for them to finish)
2. Previous run crashed without releasing lock

**To force unlock** (use carefully):

```bash
# Get lock ID from error message
terraform force-unlock <LOCK_ID>
```

### Wrong Region

**Verify region matches:**

```bash
aws configure get region
# Should match: eu-central-1 (or your configured region)
```

## Cost Estimation

### Development Environment

| Resource | Cost (Monthly) |
|----------|----------------|
| S3 Storage | ~$0.023/GB ($0.50 for ~20GB state) |
| S3 Requests | ~$0.01 (minimal operations) |
| DynamoDB | ~$0.00 (PAY_PER_REQUEST, very low usage) |
| **Total** | **~$0.51/month** |

### Production Environment

| Resource | Cost (Monthly) |
|----------|----------------|
| S3 Storage | ~$0.023/GB |
| S3 Versioning | Variable (depends on change frequency) |
| DynamoDB | ~$0.00 (PAY_PER_REQUEST) |
| DynamoDB PITR | +$0.20/GB/month (continuous backup) |
| **Total** | **~$1-5/month** (depending on state size) |

💡 **State locking operations are very cheap** - DynamoDB charges per request, and Terraform only locks during plan/apply operations.

## Cleanup (Destroy Bootstrap)

⚠️ **DANGER ZONE** - Only do this if you want to completely tear down the backend infrastructure!

### Important: `allow_destroy` Setting

The `allow_destroy` variable controls the S3 bucket's `force_destroy` attribute, which is set **only when the bucket is created**.

- If `allow_destroy = false` (production default), Terraform will refuse to delete the bucket if it contains objects
- To delete a bucket created with `allow_destroy = false`, you must first empty it manually

**To delete a protected bucket:**

```bash
# Option 1: Empty the bucket first
aws s3 rm s3://hyperswitch-prod-terraform-state --recursive

# Then destroy
terraform destroy

# Option 2: Temporarily change force_destroy via AWS CLI
aws s3api delete-bucket --bucket hyperswitch-prod-terraform-state --force-delete
```

### If Using Local Backend

```bash
cd bootstrap/dev
terraform destroy
# Type: yes
```

### If Using S3 Backend (Self-Referencing)

**You must migrate state back to local first:**

```bash
cd bootstrap/dev

# 1. Edit backend.tf - uncomment local, comment S3
# 2. Migrate state back
terraform init -migrate-state
# Type: yes

# 3. Now you can destroy
terraform destroy
# Type: yes
```

⚠️ **WARNING:** This will delete:
- The S3 bucket (and all state files stored in it!)
- The DynamoDB table
- All state history

**Only do this if you're absolutely sure!**


