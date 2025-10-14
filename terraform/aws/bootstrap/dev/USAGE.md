# Step-by-Step: Create Dev S3 State Bucket

Follow these exact steps to create your S3 bucket for Terraform state.

## Step 1: Navigate to Bootstrap Directory

```bash
cd /Users/harshvardhan.b/work/hyperswitch-suite/terraform/aws/bootstrap/dev/
```

## Step 2: Review Configuration (Optional)

```bash
# Check what bucket name will be created
cat variables.tf

# If the name is already taken, edit variables.tf:
# variable "state_bucket_name" {
#   default = "hyperswitch-dev-terraform-state-YOURNAME"
# }
```

## Step 3: Initialize Terraform

```bash
terraform init
```

**Expected output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...

Terraform has been successfully initialized!
```

## Step 4: Preview What Will Be Created

```bash
terraform plan
```

**Expected output:**
```
Terraform will perform the following actions:

  # module.terraform_state_bucket.aws_s3_bucket.this will be created
  + resource "aws_s3_bucket" "this" {
      + bucket = "hyperswitch-dev-terraform-state"
      ...
    }

  # module.terraform_state_bucket.aws_s3_bucket_public_access_block.this will be created
  ...

  # aws_s3_bucket_policy.terraform_state will be created
  ...

Plan: 6 to add, 0 to change, 0 to destroy.
```

## Step 5: Create the S3 Bucket

```bash
terraform apply
```

Type: `yes` when prompted.

**Expected output:**
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

next_steps = <<EOT

========================================
✅ Terraform State Bucket Created!
========================================

Bucket Name: hyperswitch-dev-terraform-state
Region:      eu-central-1
ARN:         arn:aws:s3:::hyperswitch-dev-terraform-state

========================================
Next Steps:
========================================
...
```

## Step 6: Verify Bucket Was Created

```bash
# List bucket
aws s3 ls | grep hyperswitch-dev-terraform-state

# Check bucket details
aws s3api get-bucket-versioning --bucket hyperswitch-dev-terraform-state
aws s3api get-bucket-encryption --bucket hyperswitch-dev-terraform-state
```

**Expected:**
- Versioning: Enabled ✅
- Encryption: AES256 ✅

## Step 7: Update Squid Proxy to Use S3 Backend

```bash
cd ../../live/dev/eu-central-1/squid-proxy/

# Backup current backend
cp backend.tf backend.tf.backup

# Update backend.tf
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/squid-proxy/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
EOF
```

## Step 8: Migrate State to S3

```bash
# Still in squid-proxy directory
terraform init -migrate-state
```

**Prompt:**
```
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value:
```

Type: `yes`

**Expected output:**
```
Successfully configured the backend "s3"!
```

## Step 9: Verify State in S3

```bash
# Check state file exists in S3
aws s3 ls s3://hyperswitch-dev-terraform-state/dev/eu-central-1/squid-proxy/

# Expected output:
# 2025-01-15 10:30:45      12345 terraform.tfstate
```

## Step 10: Clean Up Local State File (Optional)

```bash
# Still in squid-proxy directory

# Local state is now in S3, safe to delete local copies
rm -f terraform.tfstate*
rm -f backend.tf.backup

# Verify terraform still works
terraform plan
# Should connect to S3 and work normally ✅
```

## Step 11: Repeat for Envoy Proxy

```bash
cd ../envoy-proxy/

# Update backend.tf
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/envoy-proxy/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
EOF

# Migrate state
terraform init -migrate-state
# Type: yes

# Verify
aws s3 ls s3://hyperswitch-dev-terraform-state/dev/eu-central-1/envoy-proxy/
```

## Done! 🎉

Your Terraform state is now safely stored in S3 with:
- ✅ Versioning (can recover old states)
- ✅ Encryption (AES256)
- ✅ Access control (private bucket)
- ✅ Separate state per service

## Final Structure

```
S3: hyperswitch-dev-terraform-state
├── dev/
│   └── eu-central-1/
│       ├── squid-proxy/
│       │   └── terraform.tfstate
│       └── envoy-proxy/
│           └── terraform.tfstate

Local: bootstrap/dev/
└── terraform.tfstate  (bootstrap's own state)
```

## Common Issues

### Bucket name already exists

```bash
# Edit variables.tf, change:
variable "state_bucket_name" {
  default = "hyperswitch-dev-terraform-state-YOUR_SUFFIX"
}

# Re-run
terraform apply
```

### Access denied

```bash
# Check AWS credentials
aws sts get-caller-identity

# Make sure you have S3 permissions
aws s3 ls
```

### State migration failed

```bash
# Restore backup
cp backend.tf.backup backend.tf

# Re-run migration
terraform init -migrate-state -reconfigure
```

## What's Next?

1. Deploy your services: `cd squid-proxy && terraform apply`
2. Create bootstrap for integ environment (if needed)
3. Set up CI/CD pipelines
4. Add monitoring and alerts

## Need Help?

Check the [README.md](./README.md) in this directory for more details.
