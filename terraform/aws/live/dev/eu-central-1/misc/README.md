# Miscellaneous Modules

This directory contains miscellaneous Terraform modules for the Hyperswitch infrastructure.

## Current Modules

### Recon
Infrastructure for the Hyperswitch Recon service:
- **IAM Role**: OIDC-based trust policy for EKS service accounts (IRSA)
- **S3 Bucket**: Encrypted storage for recon data with versioning
- **IAM Policies**: KMS and S3 access policies

See `recon/` directory for detailed configuration.

## Note

These miscellaneous modules will be reorganized and moved to their respective module categories in the future as the infrastructure evolves.