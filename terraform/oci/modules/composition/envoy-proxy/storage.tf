# Object Storage: config delivery and access-log archival. Buckets are
# addressed by namespace + name, unique per namespace per region.

resource "oci_objectstorage_bucket" "config" {
  count = var.create_config_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = local.namespace
  name           = local.config_bucket_name

  access_type = "NoPublicAccess"
  versioning  = var.bucket_versioning
  kms_key_id  = var.bucket_kms_key_id

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Inline `content` rather than `source` so Terraform's own diff redeploys the
# object on change - oci_objectstorage_object has no etag OUTPUT attribute to
# key an explicit hash trigger off.
resource "oci_objectstorage_object" "config" {
  for_each = var.create_config_bucket ? local.config_objects : {}

  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.config[0].name
  object    = each.key
  content   = each.value

  content_type = endswith(each.key, ".yaml") || endswith(each.key, ".yml") ? "application/yaml" : "text/plain"
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

# Bucket + lifecycle policy; the ARCHIVE tier is the cold-storage tier.
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

# OCI executes lifecycle-policy rules through the regional Object Storage
# service principal (objectstorage-<region>), so the allow statement names that
# regional principal. The policy OBJECT itself is a tenancy-wide identity
# resource and is still created in the home region, like every other policy.
resource "oci_identity_policy" "logs_lifecycle" {
  count = var.create_logs_bucket ? 1 : 0

  provider = oci.home

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-logs-lifecycle"
  description    = "Authorize regional Object Storage service to execute the lifecycle policy on the ${local.display_name} logs bucket."

  statements = [
    "allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_id} where target.bucket.name = '${local.logs_bucket_name}'",
  ]

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # See identity.tf - same Oracle-Tags stamping reasoning for identity resources.
  lifecycle {
    ignore_changes = [defined_tags]
  }
}
