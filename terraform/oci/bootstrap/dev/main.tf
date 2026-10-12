# =============================================================================
# Terraform state backend bootstrap - OCI, dev, ap-mumbai-1
# =============================================================================
# Creates the Object Storage bucket that holds Terraform state for every OCI
# root. Run once, by hand, before any OCI catalog unit or live root exists:
#
#   terraform init
#   terraform plan     # review
#   terraform apply    # a human decision
#
# On AWS and GCP the equivalent step is optional - Terragrunt can create an S3
# or GCS bucket itself on first `init`. It cannot do that for `backend = "oci"`,
# so on OCI this step is mandatory. See README.md in this directory.
# =============================================================================

# Auth is delegated to the OCI CLI's own config: the provider reads the DEFAULT
# profile from ~/.oci/config and uses the security token from the session
# established by `oci session authenticate`. No credential is stated, stored or
# referenced in this repository - only the profile name.
#
# SecurityToken is the right method for this specific root and only this one:
# the bootstrap necessarily runs before any OKE cluster or instance-principal-
# eligible compute exists in a fresh compartment, so InstancePrincipal and
# OKEWorkloadIdentity - the methods later units will use - are not yet options.
provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = var.region
}

module "object_storage_backend" {
  source = "../../modules/composition/object-storage-backend"

  environment    = var.environment
  project_name   = var.project_name
  compartment_id = var.compartment_id
  region         = var.region

  # Object Storage configuration.
  # Note the arguments that are NOT here, relative to the AWS bootstrap root:
  #   allow_destroy    - no force_destroy equivalent exists on
  #                      oci_objectstorage_bucket (check sheet feature 8)
  #   sse_algorithm    - AES-256 encryption is always on and cannot be disabled
  #   dynamodb_*       - locking is native to the oci backend; no lock table
  state_bucket_name = var.state_bucket_name
  kms_key_id        = var.kms_key_id
  lifecycle_rules   = var.lifecycle_rules

  # Access for principals other than the admin running this apply.
  state_access_group_name         = var.state_access_group_name
  state_access_dynamic_group_name = var.state_access_dynamic_group_name

  backend_auth = var.backend_auth

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
