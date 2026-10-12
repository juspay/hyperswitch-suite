# container-registry

OCI Container Registry (OCIR) repositories, plus an optional compartment-level
IAM policy standing in for AWS's per-repository access policies.

Counterpart of `terraform/aws/modules/composition/ecr` and
`terraform/gcp/modules/composition/artifact-registry`. Parity analysis:
`hyperswitch-infra/docs/multi-cloud-parity/oci/modules/ecr.md`
(2 FULL / 4 PARTIAL / 1 SUBSTITUTE / 2 NONE).

## Two scopes, where AWS has one

AWS collapses "which registry" and "which folder" into the account. OCI splits
them and the split is not cosmetic:

| Concept | OCI mechanism | Appears in the pull URL? |
|---|---|---|
| Who may act on this repository | `compartment_id` | **No** |
| Which registry this repository is in | the tenancy **namespace** | **Yes** |

The pull path is `<region>.ocir.io/<tenancy-namespace>/<repository>:<tag>`. No
part of it names a compartment. Moving a repository between compartments does
not change its pull URL.

The corollary bites: **repository names are unique across the whole tenancy
namespace, regardless of compartment.** Two environments sharing a non-prod
tenancy cannot both own `hyperswitch-router`. Use `repository_name_prefix`
(e.g. `"dev/"`); the catalog unit sets it from the environment.

## How OKE pulls from this registry

Not with IAM. Read the comment block at the top of `main.tf` before wiring any
workload to these repositories - the short version is that OKE requires a
Kubernetes `docker-registry` Secret built from a long-lived OCI **Auth Token**,
and that token is deliberately not created here (it would land in Terraform
state in plaintext). This module emits `image_pull_secret_docker_server` and
`image_pull_username_prefix`; the token and the Secret belong to cluster
bootstrap, with rotation designed in.

Granting a pod's workload identity `read repos` does **not** enable image pulls.
The kubelet does the pulling and has no workload identity.

## What this module does not have, and why

| AWS feature | Status | Where it went |
|---|---|---|
| `lifecycle_policy` | **NONE** | No retention mechanism exists anywhere in `oracle/oci` 9.0.0. Out-of-band automation is the only path and it does not exist yet. |
| `repository_policy` | SUBSTITUTE | One compartment-scoped `oci_identity_policy`, off by default (`push_subjects` / `pull_subjects`). |
| `scan_on_push` | NONE on this resource | OCI's Vulnerability Scanning Service is standalone; push-triggered coverage unconfirmed. |
| `encryption_type` / `kms_key` | PARTIAL | No CMEK argument on the repository resource. |
| `image_tag_mutability_exclusion_filter` | PARTIAL | `is_immutable` is all-or-nothing. Split the repository instead. |
| `force_delete` | PARTIAL | Empty the repository out of band before `terraform destroy`. |

Every one of these is commented at the point of divergence in `main.tf` or
`variables.tf` as well; this table is the index, not the record.

## Oracle gate

Not yet consulted. Check sheet section 8 lists four items: image scanning
(NONE), repository access policy (SUBSTITUTE), image retention (NONE - the
highest blast radius), and the OKE pull-authentication difference (identity,
framework §4.4).
