# =============================================================================
# OCI dev bootstrap - real values for the ap-mumbai-1 dev compartment
# =============================================================================
# Every value here is an identifier, not a credential. Authentication comes from
# the OCI CLI's DEFAULT profile (see the provider block in main.tf); nothing in
# this repository references a key, token or secret.
#
# Usage:
#   terraform init
#   terraform plan
# =============================================================================

# Home region of the tenancy, confirmed via `oci iam region-subscription list`.
region = "ap-mumbai-1"

environment  = "dev"
project_name = "hyperswitch"

# The "dev" compartment - today the only child compartment under the tenancy
# root. This first cut is deliberately flat: no nested network/platform/data/
# apps compartments yet. That is identity-model.md's design for scale, and the
# state bucket would live above it regardless.
compartment_id = "ocid1.compartment.oc1..REPLACEME"

# =============================================================================
# Bucket configuration
# =============================================================================

# Naming follows the existing convention in both other clouds:
#   AWS: hyperswitch-sbx-ap-south-1-terraform-state
#   GCP: hyperswitch-dev-asia-south1-terraform-state
# Bucket names are unique within the tenancy namespace in a region, not globally
# the way S3's are - so no account-scoped suffix is needed.
state_bucket_name = "hyperswitch-dev-ap-mumbai-1-terraform-state"

# Oracle-managed master key. Object Storage encrypts with AES-256 either way;
# a Vault key would only change who holds the master key. Dev does not warrant
# the extra key lifecycle yet.
kms_key_id = null

# Empty: keep all state history. Matches every AWS live instantiation of the
# sibling module and the GCP module's default.
lifecycle_rules = []

# =============================================================================
# Backend consumer access
# =============================================================================
# Both null. The bootstrap apply is run by a tenancy admin over a SecurityToken
# session and needs no policy. A CI group or dynamic group is granted access
# here once identity-model.md decides which principal type CI/CD uses - guessing
# now would encode the wrong subject into a policy thirteen later modules read.
state_access_group_name         = null
state_access_dynamic_group_name = null

# Output-only. SecurityToken is what a human running terragrunt locally against
# dev uses today. Later roots running on in-tenancy compute switch this to
# InstancePrincipal, and OKE-hosted pipelines to OKEWorkloadIdentity - that
# selection belongs to identity-model.md, and this value affects nothing but the
# copy-pasteable snippet in the outputs.
backend_auth = "SecurityToken"

# =============================================================================
# Tagging
# =============================================================================

freeform_tags = {
  "team"      = "infra"
  "cost_code" = "platform"
}

# Empty: defined tags need a tag namespace to already exist in the tenancy, and
# this root is the first thing applied in it.
defined_tags = {}
