variable "compartment_id" {
  description = "OCID of the compartment the bucket is created in."
  type        = string
}

variable "region" {
  description = <<-EOT
    Region identifier, e.g. `ap-mumbai-1`. Used ONLY to compose the public
    `base_url` output - the provider's own region governs where the bucket is
    actually created. Taken as an input rather than read from a data source
    because every other module in this tree already receives it from
    `include.root.locals.region`, and a mismatch between the two would produce a
    URL that 404s while the plan looks correct.
  EOT
  type        = string
}

variable "bucket_name" {
  description = <<-EOT
    Bucket name. Unique within the tenancy's Object Storage NAMESPACE, not
    globally - unlike S3 and GCS, where the name is global. That is why this
    module does not force a tenancy/project prefix the way the GCS units do
    (project_id + region + "-sdk-assets"); the namespace already provides the
    isolation the prefix was buying.

    Not updatable in place: `oci_objectstorage_bucket.name` forces a new
    resource, and a non-empty bucket cannot be deleted by the provider at all
    (see `force_destroy` below), so a rename is a two-step manual migration.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,256}$", var.bucket_name))
    error_message = "bucket_name must be 1-256 characters of letters, digits, hyphens, underscores or periods (OCI Object Storage bucket naming rules)."
  }
}

variable "namespace" {
  description = <<-EOT
    Object Storage namespace. Null looks it up via
    `data.oci_objectstorage_namespace`, which is what every other module in this
    tree does. Passing it explicitly saves one API call per plan and lets a
    caller that already knows it (the live root's `root.hcl` carries it as a
    local) avoid the round trip.
  EOT
  type        = string
  default     = null
}

variable "access_type" {
  description = <<-EOT
    Public-access posture. Three legal values, quoted from the provider docs
    for `oci_objectstorage_bucket.access_type` because the difference between
    the last two is the whole security question for a public asset bucket:

      NoPublicAccess         - "only allows an authenticated caller to access
                               the bucket and its contents" (the default).
      ObjectReadWithoutList  - "public access is allowed for the GetObject and
                               HeadObject operations".
      ObjectRead             - "public access is allowed for the GetObject,
                               HeadObject, and ListObjects operations".

    ObjectRead is therefore STRICTLY WIDER than ObjectReadWithoutList: it lets
    an anonymous caller enumerate every object in the bucket. A browser loading
    a static asset never needs ListObjects, so a public asset bucket wants
    ObjectReadWithoutList and nothing wider.

    There is no bucket-policy resource on OCI at all, so this enum IS the whole
    anonymous-access surface - there is no second place a wider grant can hide,
    and no S3-style four-boolean public-access-block to reconcile it against.
  EOT
  type        = string
  default     = "NoPublicAccess"

  validation {
    condition     = contains(["NoPublicAccess", "ObjectRead", "ObjectReadWithoutList"], var.access_type)
    error_message = "access_type must be one of NoPublicAccess, ObjectRead, ObjectReadWithoutList."
  }
}

variable "versioning" {
  description = <<-EOT
    "Enabled" or "Disabled".

    C2 in docs/multi-cloud-parity/oci/build-log.md applies here too and is the
    reason this module has no retention-rule input: OCI Object Storage
    retention rules and versioning are MUTUALLY EXCLUSIVE in both directions.
    A module that exposed both would fail at apply rather than at plan.
  EOT
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.versioning)
    error_message = "versioning must be Enabled or Disabled."
  }
}

variable "storage_tier" {
  description = "Standard or Archive. Not updatable in place on OCI - the field forces a new bucket."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Archive"], var.storage_tier)
    error_message = "storage_tier must be Standard or Archive."
  }
}

variable "kms_key_id" {
  description = <<-EOT
    Customer-managed key OCID, or null for Oracle-managed encryption.

    Null is NOT "unencrypted". C3 in build-log.md: Object Storage encryption is
    always on (AES-256, Oracle-managed key by default) and cannot be disabled.
    This input only chooses WHOSE key, never WHETHER.
  EOT
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = <<-EOT
    Object lifecycle rules. Empty means no policy object is created at all,
    matching the state-bucket module's []-means-unused pattern.

    WATCH THE ARCHIVE ACTION. C21 in build-log.md: OCI rejects
    PutObjectLifecyclePolicy for any policy containing an ARCHIVE rule with
    400-InsufficientServicePermissions unless the Object Storage service
    principal is granted `manage object-family` in the compartment. That grant
    lives in the `oke-workload-identity` unit in hyperswitch-infra, not here.
  EOT
  type = list(object({
    name        = string
    action      = string
    time_amount = number
    time_unit   = string
    is_enabled  = optional(bool, true)
    target      = optional(string, "objects")
    object_name_filter = optional(object({
      inclusion_prefixes = optional(list(string))
      inclusion_patterns = optional(list(string))
      exclusion_patterns = optional(list(string))
    }))
  }))
  default = []
}

variable "objects" {
  description = <<-EOT
    Optional objects to upload from local content, keyed by object name.

    Object names MAY CONTAIN SLASHES and there are no directories - the "/" is
    part of the name. That is load-bearing for anything served over the native
    URL, whose shape is
      https://objectstorage.<region>.oraclecloud.com/n/<ns>/b/<bucket>/o/<name>
    so an object named `web/1.0.0/v1/HyperLoader.js` is reachable at exactly
    that path with no rewrite anywhere.

    Left empty for buckets whose contents are pushed by a build pipeline rather
    than by Terraform, which is the normal case.
  EOT
  type = map(object({
    content       = string
    content_type  = optional(string)
    cache_control = optional(string)
  }))
  default = {}
}

variable "freeform_tags" {
  description = "Freeform tags applied to the bucket."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the bucket."
  type        = map(string)
  default     = {}
}
