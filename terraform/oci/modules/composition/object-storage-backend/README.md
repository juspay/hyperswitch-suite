# object-storage-backend

The OCI Terraform state backend: an Object Storage bucket, optional lifecycle
policy, and an optional IAM policy granting a non-admin principal access to it.

Counterpart of `terraform/aws/modules/composition/terraform-backend` and
`terraform/gcp/modules/composition/gcs-backend`. Parity analysis lives in
`hyperswitch-infra/docs/multi-cloud-parity/oci/modules/terraform-backend.md`;
the backend-type decision underneath it lives in
`hyperswitch-infra/docs/multi-cloud-parity/oci/state-backend-decision.md`.

## Terraform >= 1.12.0 is a hard requirement

`versions.tf` pins `required_version = ">= 1.12.0"`, **not** the `>= 1.5.0`
floor every AWS and GCP module in this repository uses. Terraform 1.12.0 is the
release that introduced the first-party `oci` backend. On any older CLI the
bucket this module creates has no backend type able to address it. Do not copy
a `versions.tf` from the AWS or GCP tree into an OCI module and lose this.

## This module is mandatory, unlike its AWS and GCP siblings

`terraform-backend` and `gcs-backend` are optional on their clouds: Terragrunt's
`remote_state` block can create an S3 or GCS bucket itself on first `init`.
Terragrunt has that logic for exactly three backend types - `s3`, `gcs` and
`azurerm`. For `backend = "oci"` it falls back to plain HCL generation: it
writes `backend.tf` and nothing else. If this bucket does not exist, the first
`terragrunt init` in the first OCI live root fails.

Apply this once, by hand, with local state, before any OCI catalog unit exists.
There is deliberately no catalog unit or stack phase for it - a unit's own state
would need somewhere to live, which is the problem this module exists to solve.
The `terraform/oci/bootstrap/dev/` root is the entry point.

## There is no lock table, and that is correct

The AWS sibling provisions a DynamoDB table with a billing mode, capacity
settings, a PITR toggle and a KMS key, purely so the S3 backend has somewhere to
write a lock item. **There is no equivalent here and nothing is missing.**

The native `oci` backend takes a lock by creating
`<workspace_key_prefix>/<workspace>/<key>.lock` in this bucket with an
`If-None-Match: *` conditional write; if the object already exists, the write is
rejected and Terraform reports the lock as held. Locking is a property of the
backend, not infrastructure to provision, own or pay for. This is the same
mechanism the AWS live roots in this programme already migrated to
(`use_lockfile = true`), just first-class rather than opt-in.

Reviewers coming from the AWS module reliably look for the lock table. It is
absent on purpose.

## What each root.hcl needs from this module's outputs

| Output | Consumed as |
|---|---|
| `state_bucket_name` | `remote_state.config.bucket` |
| `state_bucket_namespace` | `remote_state.config.namespace` - no AWS or GCP counterpart, and it cannot be set from an environment variable |
| `state_bucket_region` | `remote_state.config.region` |
| `backend_config_formatted` | copy-pasteable `backend "oci" {}` block |

## Known gaps

**No `allow_destroy` / force-delete (check sheet feature 8, PARTIAL).**
`oci_objectstorage_bucket` has no `force_destroy`-equivalent argument in the
`oracle/oci` 9.0.0 schema, so the variable is omitted rather than accepted and
silently ignored. To tear a state backend down, empty the bucket first:

```
oci os object bulk-delete --bucket-name <name> --namespace <namespace>
terraform destroy
```

**No retention rules, unlike `gcs-backend`.** OCI documents retention rules and
object versioning as mutually exclusive - "You can't add retention rules to a
bucket that has versioning enabled. You can't enable versioning on a bucket with
active retention rules." Versioning is the state-recovery mechanism the backend
documentation itself asks for, so versioning wins and no retention variable is
exposed; one would only ever produce an apply-time API error.

**No TLS-enforcement policy, unlike the AWS module.** OCI's Object Storage and
control-plane endpoints are HTTPS only, so there is no plaintext listener for a
deny-on-insecure-transport statement to close. OCI IAM is also subject-scoped -
there is no bucket-policy resource to attach such a statement to.

## Encryption

Object Storage encrypts every object with AES-256 and encryption cannot be
turned off, so there is no `sse_algorithm`-equivalent toggle. `var.kms_key_id`
selects a customer-managed OCI Vault master key instead of the Oracle-managed
default; `is_bucket_key_enabled` follows it automatically. A principal granted
access via `state_access_group_name` / `state_access_dynamic_group_name` also
needs `use keys` on that Vault key - granted alongside the key, not here, since
the key is outside this module's compartment scope.

## Inputs

| Name | Type | Default | Required |
|---|---|---|:---:|
| `environment` | `string` | n/a | yes |
| `compartment_id` | `string` | n/a | yes |
| `region` | `string` | n/a | yes |
| `state_bucket_name` | `string` | n/a | yes |
| `project_name` | `string` | `"hyperswitch"` | no |
| `kms_key_id` | `string` | `null` | no |
| `lifecycle_rules` | `list(object(...))` | `[]` | no |
| `state_access_group_name` | `string` | `null` | no |
| `state_access_dynamic_group_name` | `string` | `null` | no |
| `backend_auth` | `string` | `"InstancePrincipal"` | no |
| `freeform_tags` | `map(string)` | `{}` | no |
| `defined_tags` | `map(string)` | `{}` | no |

## Outputs

`state_bucket_name`, `state_bucket_ocid`, `state_bucket_namespace`,
`state_bucket_region`, `state_bucket_compartment_id`, `state_access_policy_id`,
`backend_config`, `backend_config_formatted`.
