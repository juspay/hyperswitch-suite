# ============================================================================
# Bootstrap Backend Configuration - PRODUCTION
# ============================================================================
# The bootstrap creates the S3 bucket and DynamoDB table, so it starts with
# a LOCAL backend. After creation, you SHOULD migrate to S3.
#
# STEP 1: Initial bootstrap (use local backend)
# STEP 2: Run terraform apply to create S3 + DynamoDB
# STEP 3: RECOMMENDED: Uncomment S3 backend below and run: terraform init -migrate-state
# ============================================================================

# Current: LOCAL backend (initial bootstrap)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ============================================================================
# RECOMMENDED: Self-Referencing S3 Backend (Production Best Practice)
# ============================================================================
# For production, it's STRONGLY RECOMMENDED to migrate bootstrap state to S3:
# - Better disaster recovery (S3 versioning + PITR on DynamoDB)
# - Team collaboration with state locking
# - Automated backups and replication
#
# To migrate:
# 1. Uncomment the S3 backend configuration below
# 2. Comment out the local backend above
# 3. Run: terraform init -migrate-state
# 4. Confirm the migration when prompted
# 5. Backup the local terraform.tfstate file before deleting
# 6. Verify state in S3: aws s3 ls s3://hyperswitch-prod-terraform-state/bootstrap/prod/
#
# ⚠️  CRITICAL: Once migrated to S3, you cannot destroy the S3 bucket without
# first migrating the state back to local. This is a safety feature.
# ============================================================================

# terraform {
#   backend "s3" {
#     bucket         = "hyperswitch-prod-terraform-state"
#     key            = "bootstrap/prod/terraform.tfstate"  # Special path for bootstrap
#     region         = "eu-central-1"
#     dynamodb_table = "hyperswitch-prod-terraform-state-lock"
#     encrypt        = true
#   }
# }
