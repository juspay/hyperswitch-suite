locals {
  name_prefix = "${var.environment}-${var.project_name}-backend"

  # OCI has two tag namespaces where AWS and GCP have one flat map.
  # `freeform_tags` is the direct analogue of AWS `tags` / GCP `labels`;
  # `defined_tags` requires a pre-existing tag namespace in the tenancy and is
  # passed straight through untouched (var.defined_tags), because this module
  # is the first thing applied in a new compartment and cannot assume any tag
  # namespace exists yet.
  freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "terraform-backend"
      "purpose"     = "terraform-state"
      "managed_by"  = "terraform-bootstrap"
    },
    var.freeform_tags
  )

  # Policy subjects. Both are optional and both are absent by default: the
  # bootstrap apply itself is run by a human with tenancy-admin rights, so it
  # needs no policy to succeed. These exist for the *next* principal - a CI
  # runner group, or a dynamic group of instance/workload principals - which
  # must be able to read the bucket and read/write objects in it for
  # `terragrunt init` to work from anywhere other than that admin's laptop.
  state_access_subjects = compact([
    var.state_access_group_name != null ? "group ${var.state_access_group_name}" : "",
    var.state_access_dynamic_group_name != null ? "dynamic-group ${var.state_access_dynamic_group_name}" : "",
  ])

  # The minimum the native `oci` backend actually exercises:
  #   read buckets  -> HeadBucket / GetBucket, how the backend confirms the
  #                    bucket exists before touching state
  #   manage objects -> Get/Put/Delete of <key> and of the
  #                    <workspace_key_prefix>/<workspace>/<key>.lock object the
  #                    backend writes with `If-None-Match: *` to take the lock
  # Both are scoped with `target.bucket.name` so a state-backend grant cannot
  # be reused against any other bucket in the same compartment. `target.bucket.name`
  # is a supported condition variable for both the buckets and objects resource
  # types, including HeadBucket/GetBucket
  # (docs.oracle.com/en-us/iaas/Content/Identity/Reference/objectstoragepolicyreference.htm).
  #
  # Deliberately NOT granted: `manage buckets` (nothing but this bootstrap
  # module should ever create, reconfigure or delete the state bucket) and
  # `use keys` (only needed when var.kms_key_id is set, and the key lives
  # outside this module's compartment scope - grant it alongside the key).
  state_access_statements = flatten([
    for subject in local.state_access_subjects : [
      "Allow ${subject} to read buckets in compartment id ${var.compartment_id} where target.bucket.name = '${var.state_bucket_name}'",
      "Allow ${subject} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.state_bucket_name}'",
    ]
  ])
}
