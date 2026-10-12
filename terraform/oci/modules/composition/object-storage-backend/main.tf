# Terraform state backend - OCI Object Storage. Creates the place every other OCI
# root's Terraform state lives (counterpart of the AWS terraform-backend / GCP
# gcs-backend modules).
# This module is MANDATORY, not optional: Terragrunt's `remote_state` block only
# auto-creates buckets for s3/gcs/azurerm; for the `oci` backend it degrades to
# plain HCL generation and will NOT create the bucket. If this bucket does not
# exist, the first `terragrunt init` in the first OCI live root fails outright.
# Apply it once, by hand, with local state, before any catalog unit exists.

# The Object Storage namespace is a read-only, tenancy-wide singleton Oracle
# assigns at tenancy creation - a data source, never a resource. The native
# `oci` backend requires it as a literal `namespace` argument that (per
# HashiCorp) "cannot be configured through environment variables", so every OCI
# root.hcl carries it as a local. compartment_id is deliberately not passed:
# GetNamespace's optional compartmentId is for cross-tenancy lookups and expects
# a tenancy OCID, not a child compartment.
data "oci_objectstorage_namespace" "this" {}

# The state bucket
resource "oci_objectstorage_bucket" "state" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.state_bucket_name

  # Not a variable, on purpose: HashiCorp's own `oci` backend docs "highly
  # recommend" bucket versioning for state recovery, so it is fixed opinion.
  versioning = "Enabled"

  # Explicit NoPublicAccess so a reviewer sees the posture rather than infers it.
  access_type = "NoPublicAccess"

  # Encryption at rest is always-on (AES-256, "can't be turned off"); the only
  # decision is who holds the master key - Oracle by default, or a Vault key
  # supplied here.
  kms_key_id = var.kms_key_id

  # Bucket-key caching only has meaning alongside a Vault key.
  is_bucket_key_enabled = var.kms_key_id != null

  # Standard, not Archive/InfrequentAccess: state objects are read and rewritten
  # on every plan and apply. Fixed, for the same reason versioning is.
  storage_tier = "Standard"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # Two AWS/GCP features deliberately absent here:
  # 1. allow_destroy / force_destroy - oci_objectstorage_bucket has no
  #    force_destroy-equivalent, so the variable is omitted rather than accepted
  #    and silently ignored. To tear the backend down, empty the bucket out of
  #    band first, then `terraform destroy`. Friction in the safe direction.
  # 2. retention rules - OCI documents retention rules and versioning as
  #    mutually exclusive, and versioning is what the backend needs for state
  #    recovery, so versioning wins; a retention variable could only produce an
  #    apply-time API error and is not exposed.
}

# Optional object lifecycle policy. A separate resource on OCI rather than an
# inline bucket block. Count-gated on a non-empty list (keep all state history
# forever by default).
resource "oci_objectstorage_object_lifecycle_policy" "state" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  namespace = data.oci_objectstorage_namespace.this.namespace
  bucket    = oci_objectstorage_bucket.state.name

  dynamic "rules" {
    for_each = var.lifecycle_rules

    content {
      name        = rules.value.name
      action      = rules.value.action
      time_amount = rules.value.time_amount
      time_unit   = rules.value.time_unit
      is_enabled  = rules.value.is_enabled
      target      = rules.value.target

      dynamic "object_name_filter" {
        for_each = rules.value.object_name_filter != null ? [rules.value.object_name_filter] : []

        content {
          inclusion_prefixes = object_name_filter.value.inclusion_prefixes
          inclusion_patterns = object_name_filter.value.inclusion_patterns
          exclusion_patterns = object_name_filter.value.exclusion_patterns
        }
      }
    }
  }
}

# Optional IAM policy granting non-admin principals access to the state bucket.
# There is no OCI equivalent of AWS's enforce_tls bucket policy, and none is
# needed: OCI's Object Storage and control-plane endpoints are HTTPS only, so
# there is no plaintext listener to close. OCI IAM is subject-scoped (no
# bucket-policy resource), so the policy below grants a named principal access
# rather than denying the world. Created only when a subject is supplied.
resource "oci_identity_policy" "state_access" {
  count = length(local.state_access_statements) > 0 ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-access"
  description    = "Access to the ${var.environment} Terraform state bucket ${var.state_bucket_name} for the native oci backend"
  statements     = local.state_access_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# What is NOT here: the lock table. AWS's terraform-backend provisions a
# DynamoDB table so the S3 backend has somewhere to write a conditional lock
# item. There is no equivalent resource on OCI and none is missing: the native
# `oci` backend locks by creating <workspace_key_prefix>/<workspace>/<key>.lock
# with an `If-None-Match: *` conditional write on Object Storage - if the object
# exists the write is rejected and the lock is reported held. Locking is a
# property of the backend, not a resource to own and pay for (the same mechanism
# AWS's live roots already migrated to via `use_lockfile = true`).
