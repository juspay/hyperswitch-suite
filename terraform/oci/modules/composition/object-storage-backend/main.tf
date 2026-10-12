# =============================================================================
# Terraform state backend - OCI Object Storage
# =============================================================================
# The OCI counterpart of aws/modules/composition/terraform-backend and
# gcp/modules/composition/gcs-backend: it creates the place every other OCI
# root's Terraform state will live.
#
# It differs from both siblings in one structural way: on OCI this module is
# MANDATORY, not an optional hardening extra. Terragrunt's `remote_state` block
# has real bucket-creating logic for exactly three backend types - s3, gcs and
# azurerm. For `backend = "oci"` it degrades to plain HCL generation: it will
# happily write backend.tf, but it will not check whether the bucket exists,
# will not create it, and has no skip_bucket_creation-equivalent to ask it to.
# If this bucket does not exist, the first `terragrunt init` in the first OCI
# live root fails outright.
# See docs/multi-cloud-parity/oci/state-backend-decision.md section 2.
#
# Applied once, by hand, with local state, before any catalog unit exists.
# There is no catalog unit for this module on any cloud, by construction.
# =============================================================================

# The Object Storage namespace is a read-only, tenancy-wide singleton Oracle
# assigns at tenancy creation - a data source, never a resource. It has no AWS
# or GCP counterpart: it is not a name anyone chooses, but the native `oci`
# backend requires it as a literal `namespace` argument that (per HashiCorp's
# backend docs) "cannot be configured through environment variables". Every OCI
# root.hcl therefore needs it as a local, the way GCP roots carry project_id.
#
# compartment_id is deliberately not passed: GetNamespace's optional
# compartmentId exists for cross-tenancy lookups and expects a tenancy OCID,
# not an arbitrary child compartment.
data "oci_objectstorage_namespace" "this" {}

# -----------------------------------------------------------------------------
# The state bucket
# -----------------------------------------------------------------------------
resource "oci_objectstorage_bucket" "state" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = var.state_bucket_name

  # Not a variable, on purpose. HashiCorp's own `oci` backend documentation
  # says it is "highly recommended that you enable Bucket Versioning on the
  # object storage bucket to allow for state recovery in the case of accidental
  # deletions and human error" - a state bucket without versioning is
  # misconfigured in every environment, so this is the module's fixed opinion
  # rather than something a stack can turn off.
  versioning = "Enabled"

  # AWS spends four booleans here (block_public_acls, block_public_policy,
  # ignore_public_acls, restrict_public_buckets) to reach a posture OCI
  # expresses as one enum, whose default is already NoPublicAccess. Stated
  # explicitly anyway so a reviewer can see the posture rather than infer it.
  access_type = "NoPublicAccess"

  # Encryption at rest has no on/off toggle to port from the AWS module's
  # `sse_algorithm`: Object Storage encrypts every object with AES-256 and
  # "Encryption is enabled by default and can't be turned off"
  # (docs.oracle.com/en-us/iaas/Content/Object/Tasks/encryption.htm). The only
  # decision left is who holds the master key - Oracle by default, or a Vault
  # key supplied here. null keeps the Oracle-managed key.
  kms_key_id = var.kms_key_id

  # Bucket-key caching only has meaning alongside a Vault key.
  is_bucket_key_enabled = var.kms_key_id != null

  # Standard, not Archive/InfrequentAccess: state objects are read and
  # rewritten on every plan and apply. Fixed, for the same reason versioning is.
  storage_tier = "Standard"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # Two AWS/GCP features that are deliberately absent here, so their absence is
  # not read later as an oversight:
  #
  # 1. allow_destroy / force_destroy - PARTIAL (check sheet feature 8).
  #    oci_objectstorage_bucket has no force_destroy-equivalent argument
  #    (confirmed against the oracle/oci 9.0.0 provider schema), so AWS's
  #    `allow_destroy` and GCP's `allow_destroy` have nothing to map onto. The
  #    variable is omitted rather than accepted and silently ignored. To tear a
  #    state backend down, empty the bucket out of band first:
  #      oci os object bulk-delete --bucket-name <name> --namespace <namespace>
  #    then `terraform destroy`. The friction is asymmetric in the safe
  #    direction and acceptable - see the check sheet's section 4.
  #
  # 2. retention rules - a real divergence from gcs-backend's
  #    retention_period_seconds / retention_policy_locked, and NOT merely a
  #    naming difference. OCI documents retention rules and versioning as
  #    mutually exclusive: "You can't add retention rules to a bucket that has
  #    versioning enabled. You can't enable versioning on a bucket with active
  #    retention rules."
  #    (docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingretentionrules.htm)
  #    Versioning is the state-recovery mechanism the backend itself asks for,
  #    so versioning wins. Exposing a retention variable on this module could
  #    only ever produce an apply-time API error, so it is not exposed at all.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# Optional object lifecycle policy
# -----------------------------------------------------------------------------
# On OCI this is a separate resource rather than an inline block on the bucket
# (a structural difference from both AWS's and GCP's inline lifecycle_rules, not
# a capability gap). Count-gated on a non-empty list, mirroring AWS's own
# []-default-means-unused pattern - which is what every AWS live instantiation
# reviewed actually uses, i.e. keep all state history forever.
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

# -----------------------------------------------------------------------------
# Optional IAM policy granting non-admin principals access to the state bucket
# -----------------------------------------------------------------------------
# There is no OCI equivalent of AWS's aws_s3_bucket_policy.enforce_tls, and none
# is needed: OCI's Object Storage and control-plane API endpoints are HTTPS
# only, so there is no plaintext-HTTP listener for a deny-on-insecure-transport
# statement to close. The AWS statement exists to shut a door OCI's API does not
# have. OCI IAM is also subject-scoped rather than resource-scoped - there is no
# bucket-policy resource at all - so the policy below grants a named principal
# access rather than denying the world.
#
# Created only when a subject is supplied. Both variables default to null, which
# means the common case (a tenancy admin bootstrapping by hand) creates no
# policy and needs none.
resource "oci_identity_policy" "state_access" {
  count = length(local.state_access_statements) > 0 ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-access"
  description    = "Access to the ${var.environment} Terraform state bucket ${var.state_bucket_name} for the native oci backend"
  statements     = local.state_access_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# What is NOT here: the lock table
# -----------------------------------------------------------------------------
# AWS's terraform-backend module provisions a second piece of infrastructure - a
# DynamoDB table with its own billing mode, capacity, PITR toggle and KMS key -
# purely so the S3 backend has somewhere to write a conditional lock item. There
# is no equivalent resource on OCI and none is missing.
#
# The native `oci` backend locks by creating
# <workspace_key_prefix>/<workspace>/<key>.lock with an `If-None-Match: *`
# conditional write against Object Storage's own API; if the object exists, the
# write is rejected and Terraform reports the lock as held. Locking is a
# property of the backend, not a resource to own and pay for. This is the same
# mechanism AWS's own live roots in this programme have already migrated to
# (`use_lockfile = true`), just first-class instead of opt-in.
#
# Recorded here, and in the README, because a reviewer used to the AWS sibling
# will look for the lock table and its absence is correct, not incomplete.
# See docs/multi-cloud-parity/oci/state-backend-decision.md section 1.
