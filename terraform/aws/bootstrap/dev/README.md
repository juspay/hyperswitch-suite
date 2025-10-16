# Dev Environment Bootstrap

Creates the S3 bucket for storing Terraform state files in the dev environment.

## Purpose

This is a **one-time setup** to create the infrastructure needed to store Terraform state remotely in S3.

## What This Creates

- ✅ S3 bucket: `hyperswitch-dev-terraform-state`
- ✅ Versioning enabled (track state history)
- ✅ Encryption enabled (AES256)
- ✅ Public access blocked (security)
- ✅ TLS enforcement (prevent unencrypted access)

## Quick Start

```bash
# 1. Navigate to this directory
cd terraform/aws/bootstrap/dev/

# 2. Initialize Terraform
terraform init

# 3. Review what will be created
terraform plan

# 4. Create the S3 bucket
terraform apply

# Output will show bucket name and next steps
```

## Expected Output

```
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

state_bucket_name = "hyperswitch-dev-terraform-state"
state_bucket_arn = "arn:aws:s3:::hyperswitch-dev-terraform-state"
state_bucket_region = "eu-central-1"

next_steps = <<EOT
========================================
✅ Terraform State Bucket Created!
========================================
...
```

## After Bootstrap: Migrate Your Services

### For Squid Proxy

```bash
cd ../../live/dev/eu-central-1/squid-proxy/

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

# Migrate state
terraform init -migrate-state

# Type: yes when prompted

# Verify
aws s3 ls s3://hyperswitch-dev-terraform-state/dev/eu-central-1/squid-proxy/
```

### For Envoy Proxy

```bash
cd ../../live/dev/eu-central-1/envoy-proxy/

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

## State File Organization

After migration, your S3 bucket will contain:

```
s3://hyperswitch-dev-terraform-state/
├── dev/
│   └── eu-central-1/
│       ├── squid-proxy/
│       │   └── terraform.tfstate
│       └── envoy-proxy/
│           └── terraform.tfstate
```

Note: Bootstrap state itself remains local (in this directory as `terraform.tfstate`)

## Important Notes

### ⚠️ Local State File

The bootstrap's state file (`terraform.tfstate`) is stored **locally** in this directory.

**Keep it safe:**
- Commit to git (if using private repo)
- Or backup manually
- Or migrate to S3 later (optional)

### 🔒 Security

- State bucket is **private** (no public access)
- **Encryption** enabled by default
- **Versioning** enabled (can recover old states)
- **TLS** enforced (must use HTTPS)

### 🌍 Bucket Name Must Be Unique

If you get this error:

```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Solution:** Change the bucket name in `variables.tf`:

```hcl
variable "state_bucket_name" {
  default = "hyperswitch-dev-terraform-state-YOUR_UNIQUE_SUFFIX"
}
```

## Troubleshooting

### Can't create bucket (already exists)

Someone else (or another AWS account) is using that bucket name.

**Fix:** Change `state_bucket_name` in `variables.tf`

### Access denied

Check your AWS credentials:

```bash
aws sts get-caller-identity
aws s3 ls  # Test basic S3 access
```

### Wrong region

Make sure you're creating the bucket in the right region:

```bash
# Check your region
aws configure get region

# Should match variables.tf (eu-central-1)
```

## Cleanup (⚠️ Dangerous!)

**Only if you want to start over:**

```bash
# This will DELETE the state bucket
terraform destroy

# WARNING: This will delete ALL state files stored in the bucket!
# Only do this if you're sure!
```

## What's Next?

1. ✅ Bootstrap complete
2. Update backend.tf in squid-proxy
3. Update backend.tf in envoy-proxy
4. Migrate states using `terraform init -migrate-state`
5. Deploy your services!

## Need Help?

- Check the main [README.md](../../README.md) for general Terraform info
- Check [QUICKSTART.md](../../QUICKSTART.md) for quick deployment guide
- Review AWS CLI commands if you prefer manual bucket creation
