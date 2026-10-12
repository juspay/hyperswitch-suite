# =============================================================================
# Object Storage: config delivery, the domain allowlist, and log archival
# =============================================================================
# Buckets are addressed by namespace + name and are unique per namespace per
# region, NOT globally the way S3 buckets are.

resource "oci_objectstorage_bucket" "config" {
  count = var.create_config_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = local.config_bucket_name

  access_type = "NoPublicAccess"

  # Versioning matters more here than on the ingress side: this bucket holds
  # the domain allowlist, and a bad allowlist push breaks every outbound call
  # the platform makes. Object versions are the rollback path.
  versioning = var.bucket_versioning
  kms_key_id = var.bucket_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# FULL - check sheet features 7 and 8.
#
# Two objects with materially different lifecycles land in the same bucket, and
# the difference is the point:
#
#   squid.conf       changing it needs an instance restart or a reconfigure at
#                    boot - it is deployment-shaped.
#   allowedlist.txt  changing it needs NOTHING but this apply. The image's
#                    15-minute timer refetches the object and runs
#                    `squid -k reconfigure`, so the allowlist changes with no
#                    instance replaced and no connection dropped. That is the
#                    dynamic-whitelist-hot-reload feature, and it is the one
#                    part of this module that is FULL parity with AWS by way of
#                    a mechanism that lives outside Terraform entirely.
#
# Inline `content` rather than `source` so Terraform's own diff redeploys on
# change - equivalent to the AWS module's content + etag = filemd5() pattern,
# and necessary because oci_objectstorage_object exposes no etag OUTPUT
# attribute to key an explicit trigger off.
resource "oci_objectstorage_object" "config" {
  for_each = var.create_config_bucket ? local.config_objects : {}

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.config[0].name
  object    = each.key
  content   = each.value

  content_type = "text/plain"
}

resource "oci_objectstorage_bucket" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = local.logs_bucket_name

  access_type = "NoPublicAccess"
  versioning  = var.bucket_versioning
  kms_key_id  = var.bucket_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# The AWS module configures NO lifecycle rules on its logs bucket. This adds
# them deliberately rather than porting the omission: Squid's access log is the
# audit trail for every outbound call from a card-data environment, so both an
# archive transition and an expiry deserve to be stated rather than defaulted
# to "keep forever in standard storage".
resource "oci_objectstorage_object_lifecycle_policy" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.logs[0].name

  dynamic "rules" {
    for_each = var.log_archive_after_days != null ? [1] : []

    content {
      name        = "archive"
      action      = "ARCHIVE"
      target      = "objects"
      time_amount = tostring(var.log_archive_after_days)
      time_unit   = "DAYS"
      is_enabled  = true
    }
  }

  rules {
    name        = "expire"
    action      = "DELETE"
    target      = "objects"
    time_amount = tostring(var.log_retention_days)
    time_unit   = "DAYS"
    is_enabled  = true
  }
}
