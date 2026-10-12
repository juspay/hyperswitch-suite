locals {
  name_prefix = "${var.environment}-${var.project_name}-backend"

  # OCI has two tag namespaces where AWS/GCP have one flat map. freeform_tags is
  # the direct analogue of AWS `tags` / GCP `labels`; defined_tags requires a
  # pre-existing namespace in the tenancy and is passed straight through, because
  # this module is the first thing applied in a new compartment and cannot assume
  # any tag namespace exists yet.
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

  # Policy subjects, both optional and both absent by default: the bootstrap
  # apply itself runs as a human with tenancy-admin rights, so it needs no policy
  # - these exist for the NEXT principal (a CI runner group, or a dynamic group
  # of workload principals) that must read/write the bucket for `terragrunt init`
  # to work away from that admin's laptop.
  state_access_subjects = compact([
    var.state_access_group_name != null ? "group ${var.state_access_group_name}" : "",
    var.state_access_dynamic_group_name != null ? "dynamic-group ${var.state_access_dynamic_group_name}" : "",
  ])

  # The minimum the native `oci` backend actually exercises: `read buckets`
  # (confirm the bucket exists) and `manage objects` (Get/Put/Delete of <key>
  # and of the <workspace_key_prefix>/<workspace>/<key>.lock lock object). Both
  # scoped with target.bucket.name so the grant cannot be reused against any
  # other bucket in the compartment. Deliberately NOT granted: `manage buckets`
  # and `use keys` (the key lives outside this module's compartment scope).
  state_access_statements = flatten([
    for subject in local.state_access_subjects : [
      "Allow ${subject} to read buckets in compartment id ${var.compartment_id} where target.bucket.name = '${var.state_bucket_name}'",
      "Allow ${subject} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${var.state_bucket_name}'",
    ]
  ])
}
