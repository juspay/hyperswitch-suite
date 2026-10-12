# =============================================================================
# composition/object-storage-bucket - a generic Object Storage bucket
# =============================================================================
# WHY A NEW MODULE RATHER THAN REUSING composition/object-storage-backend.
# That module is not generic and must not be made generic: it hardcodes
# `versioning = "Enabled"` and `access_type = "NoPublicAccess"` as posture (its
# own comments say state-recovery requires both), derives the bucket name from
# `state_bucket_name`, and creates an `oci_identity_policy` granting a named
# group access to the STATE bucket. Widening it to serve a public asset bucket
# would mean making its two posture literals into inputs, which is precisely the
# guarantee the Terraform-state bucket exists to keep.
#
# WHAT THIS REPLACES ON THE OTHER CLOUDS. GCP's deleted
# `apps/hyperswitch-sdk-assets` unit sourced
# `tfr:///terraform-google-modules/cloud-storage//modules/simple_bucket`
# directly from the public registry. There is no OCI equivalent worth using -
# docs/multi-cloud-parity/oci/provider-facts.md records that OCI has essentially
# one well-maintained registry module (oracle-terraform-modules/oke/oci), so
# DIRECT-RESOURCE is the default here and REGISTRY-MODULE is the exception.
# Strategy: DIRECT-RESOURCE.
#
# NOT IN THIS MODULE, deliberately:
#   * no bucket policy - `oci_objectstorage_bucket_policy` does not exist. OCI
#     IAM is subject-scoped; a grant to a named principal is an
#     `oci_identity_policy` statement, and in this platform those statements are
#     concentrated in ONE per-environment policy object owned by the
#     `oke-workload-identity` unit (100-policy-objects-per-tenancy limit - see
#     that unit's header). A bucket module that created its own policy object
#     would be the exact failure that layout exists to prevent.
#   * no `force_destroy` - the argument does not exist on OCI, and the API
#     refuses to delete a non-empty bucket. Teardown is
#     `oci os object bulk-delete --bucket-name <name> --namespace <ns>` first.
#   * no CORS configuration - there is no CORS resource or argument on
#     `oci_objectstorage_bucket`, and none is needed: the native Object Storage
#     endpoint already returns `access-control-allow-origin: *` on every
#     response (verified live against
#     objectstorage.ap-mumbai-1.oraclecloud.com, 2026-09-05).
# =============================================================================

data "oci_objectstorage_namespace" "this" {
  count = var.namespace == null ? 1 : 0

  compartment_id = var.compartment_id
}

locals {
  namespace = coalesce(var.namespace, one(data.oci_objectstorage_namespace.this[*].namespace))

  # The public read URL prefix a browser or a CDN origin would use. Composed
  # here rather than in the caller so exactly one place knows the shape.
  #
  # This endpoint carries a real, publicly-trusted TLS certificate with no
  # custom domain and no certificate resource anywhere in Terraform - verified
  # 2026-09-05 against ap-mumbai-1: CN=objectstorage.ap-mumbai-1.oraclecloud.com,
  # issued by DigiCert Global G2 TLS RSA SHA256 2020 CA1. That is the whole
  # reason the OCI port of `hyperswitch-sdk-assets` needs no Cloud-CDN-equivalent
  # and no sslip.io wildcard-cert workaround.
  base_url = "https://objectstorage.${var.region}.oraclecloud.com/n/${local.namespace}/b/${var.bucket_name}/o"
}

resource "oci_objectstorage_bucket" "this" {
  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = var.bucket_name

  # See variables.tf. This enum is the ENTIRE anonymous-access surface on OCI:
  # there is no bucket policy and no public-access-block to reconcile against.
  access_type = var.access_type

  versioning   = var.versioning
  storage_tier = var.storage_tier

  # Null = Oracle-managed key. Encryption itself is not optional (C3).
  kms_key_id = var.kms_key_id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = var.access_type == "NoPublicAccess" || var.kms_key_id == null
      error_message = "A publicly readable bucket cannot use a customer-managed key: anonymous GetObject has no principal to grant `use keys` to, so every anonymous read would fail at decrypt time. Choose NoPublicAccess, or leave kms_key_id null and rely on the Oracle-managed key (which is applied regardless - encryption is never off)."
    }
  }
}

# A separate resource on OCI rather than an inline block, the same structural
# difference composition/object-storage-backend documents.
resource "oci_objectstorage_object_lifecycle_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.this.name

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

resource "oci_objectstorage_object" "this" {
  for_each = var.objects

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.this.name
  object    = each.key

  content       = each.value.content
  content_type  = each.value.content_type
  cache_control = each.value.cache_control
}
