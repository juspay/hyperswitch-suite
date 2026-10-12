# A generic Object Storage bucket (DIRECT-RESOURCE strategy). No bucket-policy resource exists on
# OCI; principal grants are concentrated in the central per-environment policy object, not here.

data "oci_objectstorage_namespace" "this" {
  count = var.namespace == null ? 1 : 0

  compartment_id = var.compartment_id
}

locals {
  namespace = coalesce(var.namespace, one(data.oci_objectstorage_namespace.this[*].namespace))

  # The public read URL prefix a browser or CDN origin would use. Composed here so
  # exactly one place knows the shape. The endpoint carries a real, publicly-trusted
  # TLS certificate with no custom domain or certificate resource.
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
