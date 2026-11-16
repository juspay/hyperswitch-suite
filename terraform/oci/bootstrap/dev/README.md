# OCI state backend bootstrap - dev / ap-mumbai-1

**This is a one-time, human-run step.** It creates the Object Storage bucket
that every other OCI Terraform root stores its state in.

```
terraform init
terraform plan     # review the plan
```

**`terraform apply` is a human decision and is not run by any agent.** Review
the plan, then apply it yourself.

## Why this exists and why it is not a catalog unit

Every other OCI catalog unit's `remote_state` block writes its state into the
bucket this root creates. That bucket has to exist first, so this root cannot
use the backend it is creating - it uses `backend "local"` (see `backend.tf`),
exactly as `terraform/aws/bootstrap/dev/` does.

Unlike AWS and GCP, this step is **mandatory, not optional**. Terragrunt's
`remote_state` block can create the state bucket itself for `backend = "s3"`,
`"gcs"` and `"azurerm"`. It has no such logic for `backend = "oci"` - it only
generates the `backend.tf` HCL. If this bucket does not exist, the very first
`terragrunt init` in the very first OCI live root fails with a bucket-not-found
error from the backend, and Terragrunt will not paper over it.

## What it creates

| Resource | Notes |
|---|---|
| `oci_objectstorage_bucket.state` | versioned, `NoPublicAccess`, Standard tier, Oracle-managed encryption key |
| `oci_objectstorage_object_lifecycle_policy.state` | only when `lifecycle_rules` is non-empty - it is empty here, so not created |
| `oci_identity_policy.state_access` | only when an access group or dynamic group is named - neither is here, so not created |

There is **no lock table**. The native `oci` backend locks with an
`If-None-Match` conditional write on a `.lock` object inside this same bucket,
so there is no DynamoDB-equivalent to provision. The AWS sibling's DynamoDB
table has no counterpart here and none is missing.

## Requirements

- **Terraform >= 1.12.0.** The first-party `oci` backend was added in 1.12.0.
  On an older CLI the bucket this creates is unusable as a backend.
- OCI CLI profile `DEFAULT` in `~/.oci/config` with a live session
  (`oci session authenticate`). The provider reads that profile itself via
  `auth = "SecurityToken"`; no credential is stored in or read from this
  repository.
- Permission to create a bucket in the target compartment.

## Values

All in `terraform.tfvars`, hardcoded because this root is run directly, once:

| | |
|---|---|
| Region | `ap-mumbai-1` (tenancy home region) |
| Compartment | `ocid1.compartment.oc1..REPLACEME` ("dev") |
| Bucket | `hyperswitch-dev-ap-mumbai-1-terraform-state` |
| Namespace | read at plan time from `data "oci_objectstorage_namespace"` and returned as an output |

This cut uses a **flat compartment**: everything lands directly in "dev". The
nested network/platform/data/apps compartment tree in `identity-model.md` is the
eventual design for scale, not what this proof-of-pipeline needs.

## After applying

The apply prints a `next_steps` output containing the two values every OCI
`root.hcl` in `hyperswitch-infra` needs as locals - `state_bucket_name` and
`object_storage_namespace` - plus a ready-made `backend "oci" {}` block. Nothing
else in the OCI programme can `terragrunt init` until those are wired up.

## Tearing it down

`oci_objectstorage_bucket` has no `force_destroy` equivalent, so `terraform
destroy` fails while the bucket still holds state objects. Empty it first:

```
oci os object bulk-delete \
  --bucket-name hyperswitch-dev-ap-mumbai-1-terraform-state \
  --namespace $(terraform output -raw object_storage_namespace)
```

Obviously this deletes the state of every OCI root in the environment.
