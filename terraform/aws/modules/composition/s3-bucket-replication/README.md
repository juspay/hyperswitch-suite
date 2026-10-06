# s3-bucket-replication

Glue module for same-account **S3 Cross-Region Replication**. It wires two
`base/s3-bucket` instances across two regions — a destination (replica) bucket via
the `aws.replica` provider, and the source bucket whose replication rule + IAM role
(both produced by `base/s3-bucket`) point at it. **No replication logic lives here** —
it's in `base/s3-bucket`.

The caller passes two providers:

```hcl
module "crr" {
  source    = "../../modules/composition/s3-bucket-replication"
  providers = { aws = aws, aws.replica = aws.replica }

  source_bucket_name      = "my-app-data"
  destination_bucket_name = "my-app-data-replica"

  # Retrofit onto an existing, already-versioned source bucket:
  create_source_bucket = false

  replication_prefix       = null   # whole bucket; or "incoming/" to scope
  replicate_delete_markers = true
}
```

- `create_source_bucket = false` attaches replication to a pre-existing (already
  versioned) source bucket instead of creating one. `create_destination_bucket = false`
  does the same for the replica.
- When `replication_prefix` is set, `base/s3-bucket` scopes the role's object
  permissions to that prefix.
- **Encryption:** `AES256` (default) needs nothing extra. For `aws:kms`, pass existing
  `source_kms_key_arn` / `destination_kms_key_arn` — this module does **not** create KMS
  keys (that would be logic, not glue).
- **Backfill:** live replication only copies objects written *after* it's enabled.
  Existing objects need a one-time S3 Batch Replication job (role must also trust
  `batchoperations.s3.amazonaws.com` + `s3:InitiateReplication`).
