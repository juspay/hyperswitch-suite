# file-storage

OCI File Storage: file systems, one shared mount target, per-file-system NFS
exports, and optional filesystem snapshot policies.

Counterpart of `terraform/aws/modules/composition/efs` and
`terraform/gcp/modules/composition/filestore`. Parity analysis:
`hyperswitch-infra/docs/multi-cloud-parity/oci/modules/efs.md`
(7 FULL / 1 PARTIAL / 3 SUBSTITUTE / 1 NONE).

## Three resources, not four

`main.tf` manages `oci_file_storage_mount_target`,
`oci_file_storage_file_system` and `oci_file_storage_export`, plus an optional
`oci_file_storage_filesystem_snapshot_policy`.

It does **not** manage `oci_file_storage_export_set`. The check sheet left this
open (section 9, question 1); the answer, from the `oracle/oci` 9.0.0 schema, is
that the resource requires a `mount_target_id` and has every other attribute
computed - it tunes an export set the mount target already created, it does not
create one. The module reads `mount_target.export_set_id`.

## One mount target, and why that is not a shortcut

AWS builds one mount target per AZ, keyed by subnet. Here there is one, because:

- OCI subnets are **regional**, so there is no per-AZ set of subnets to fan out
  across; and
- `ap-mumbai-1` has **one availability domain**, so there is no second AD to
  place a peer mount target into.

AWS's multi-AZ mount-target redundancy has no equivalent, and none can be
produced from this layer. Recorded, not worked around.

Bandwidth follows the mount target, not the file system
(`mount_target_requested_throughput`). Every file system exported through it
shares the ceiling, there is no elastic auto-scaling mode, and tier changes carry
a 30-day billing commitment. Give a busy file system its own module
instantiation rather than adding it behind an existing mount target.

## Mounting from OKE

Static provisioning with `fss.csi.oraclecloud.com`. The `csi_volume_handles`
output produces the exact `volumeHandle` string
(`<FileSystemOCID>:<MountTargetIP>:<path>`); `accessModes` must be
`ReadWriteMany`. `terragrunt plan` cannot prove this path works - it is the
smoke test.

## What this module does not have, and why

| AWS feature | Status | Where it went |
|---|---|---|
| `lifecycle_policy` (IA / Archive tiering) | **NONE** | No infrequent-access storage class exists for OCI file data. Actively used on AWS today (all six live roots). |
| `enable_backup_policy` (AWS Backup) | SUBSTITUTE | `oci_file_storage_filesystem_snapshot_policy` - real schedule and retention, but File-Storage-only, no cross-service view. |
| `access_points` | SUBSTITUTE | One export per path. Does **not** enforce POSIX identity; that would move to mount-target-wide Kerberos/LDAP id mapping. |
| `file_system_policy` | SUBSTITUTE | A compartment-level IAM policy authored outside this module. Unused on AWS today. |
| `throughput_mode` / `provisioned_throughput_in_mibps` | PARTIAL | Mount-target-level `requested_throughput`. |
| `performance_mode` | absent | No OCI counterpart; no live root sets anything but the AWS default. |
| `create_security_group` and its rules | reshaped | The module owns an **empty** NSG (`create_nsg`, default true); `security-rules` writes the NFS rules into it. See the deviation note below. |
| `replication_configuration` | not carried | `oci_file_storage_replication` exists (feature 11, FULL) but no live root replicates today. |

Export options are the one place OCI is **richer**: this AWS module exposes no
NFS export controls at all. Defaults are pinned in `locals.tf`
(`access = READ_WRITE`, `identity_squash = NONE`) rather than inherited, because
OCI's own default (`identity_squash = ROOT`) is stricter than current AWS
behaviour and would be a silent change.

## Two recorded deviations from the check sheet

1. **This module owns an NSG.** `efs.md` section 5 proposed accepting only
   pre-existing NSG OCIDs. The sibling wave-1 modules (`database`,
   `oci-cache-valkey`) own an empty NSG that `security-rules` populates, and
   `vpc-network` strips the VCN default security list to zero rules - so a
   mount target with no NSG is unreachable. `create_nsg` defaults true and the
   NSG is created empty, which fails closed.
2. **Mount-target IPs come from `ip_address`, not a `data "oci_core_private_ip"`
   lookup.** The sheet proposed the lookup; it cannot be written, because
   `private_ip_ids` is computed and a `for_each` over it is unknown at plan time.
   See the header comment in `outputs.tf`.

It also closes check sheet open question 1 (`export_set` needs no managed
resource).

## Oracle gate

Not yet consulted. Check sheet section 8: lifecycle tiering (NONE), snapshot-based
backup (SUBSTITUTE), access points (SUBSTITUTE), file-system policy (SUBSTITUTE,
to be gated together with `container-registry`'s equivalent), and the NSG usage
(framework §4.3, network security model).
