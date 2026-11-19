# Hyperswitch unit: additional S3 buckets

Requires Terragrunt >= 1.2.0 for stable dependency expansion.

Set `additional_s3_bucket_config_paths` in the calling stack's unit values.
Each value is a path to a composition/s3 unit, relative to the generated
Hyperswitch unit. Keys are caller-defined and are preserved in the module
input and output; the unit has no environment-specific bucket labels.

```hcl
values = {
  additional_s3_bucket_config_paths = {
    extra_themes  = "../../../../global/us-east-1/s3/dashboard-integ"
    extra_uploads = "../../../../global/us-east-1/s3/file-uploads-integ"
  }
}
```

The unit expands one dependency per entry and passes `source_bucket_arn` to
`additional_s3_buckets[name].bucket_arn`. When `is_passive = true`, it passes
`replica_bucket_arn` instead. Omitting the map or passing `{}` creates no
additional dependency instances and passes an empty map to the module.

The module exposes `additional_s3_buckets[name].bucket_name` and `.bucket_arn`.
The module grants ListBucket, GetObject, PutObject and GetObjectVersion by
default. Override permissions by matching the same caller-defined keys:

```hcl
additional_s3_bucket_permissions = {
  extra_themes = {
    bucket_actions = []
    object_actions = ["s3:GetObject", "s3:PutObject"]
  }
}
```

This map only configures actions; bucket ARNs always come from dependencies.
Other custom policies can still be passed through `additional_iam_policies`.
Shallow merging preserves existing state outputs and supplies mocks for missing outputs. Mock usage is not restricted by Terraform command.

## Release order

Publish the accompanying Hyperswitch module changes as `hyperswitch-v0.2.3`,
which this unit now references, before releasing or deploying the updated unit.
Then publish this catalog unit and update consuming stacks to the new unit ref.
The module tag must include the additional bucket outputs and IAM policy.
