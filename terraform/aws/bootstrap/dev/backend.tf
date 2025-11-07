# ============================================================================
# Bootstrap Backend Configuration
# ============================================================================
# The bootstrap creates the S3 bucket and DynamoDB table, so it starts with
# a LOCAL backend. After creation, you can optionally migrate to S3.
#
# STEP 1: Initial bootstrap (use local backend)
# STEP 2: Run terraform apply to create S3 + DynamoDB
# STEP 3: (Optional) Uncomment S3 backend below and run: terraform init -migrate-state
# ============================================================================

# Current: LOCAL backend (initial bootstrap)
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# ============================================================================
# OPTIONAL: Self-Referencing S3 Backend
# ============================================================================
# After the bootstrap infrastructure is created, you can migrate to storing
# the bootstrap's own state in S3 for better team collaboration and backup.
#
# To migrate:
# 1. Uncomment the S3 backend configuration below
# 2. Comment out the local backend above
# 3. Run: terraform init -migrate-state
# 4. Confirm the migration when prompted
# 5. Delete the local terraform.tfstate file (it's now in S3!)
#
# WARNING: Once migrated to S3, you cannot destroy the S3 bucket without
# first migrating the state back to local.
# ============================================================================

terraform {
  backend "s3" {
    bucket         = "hyperswitch-dev-terraform-state"
    key            = "terraform-backend/terraform.tfstate"  # Special path for bootstrap
    region         = "eu-central-1"
    dynamodb_table = "hyperswitch-dev-terraform-state-lock"
    encrypt        = true
  }
}
