# file-storage

OCI File Storage: file systems, one shared mount target, per-file-system NFS
exports, and optional filesystem snapshot policies.

## Resources

`main.tf` manages `oci_file_storage_mount_target`,
`oci_file_storage_file_system`, `oci_file_storage_export`, and an optional
`oci_file_storage_filesystem_snapshot_policy`. It does **not** manage
`oci_file_storage_export_set` (the mount target already creates one — the module
reads `mount_target.export_set_id`).

## One mount target

There is one mount target, not one per AZ, because OCI subnets are regional and
`ap-mumbai-1` has a single availability domain. Bandwidth follows the mount
target, not the file system (`mount_target_requested_throughput`): every file
system exported through it shares the ceiling, there is no elastic auto-scaling,
and tier changes carry a 30-day billing commitment. Give a busy file system its
own module instantiation.

## Mounting from OKE

Static provisioning with `fss.csi.oraclecloud.com`. The `csi_volume_handles`
output produces the `volumeHandle` string (`<FileSystemOCID>:<MountTargetIP>:<path>`);
`accessModes` must be `ReadWriteMany`.

## What this module does not have, and why

- No infrequent-access / archive storage class exists for OCI file data.
- Backups use `oci_file_storage_filesystem_snapshot_policy` (schedule + retention,
  File-Storage-only).
- Access is one export per path; it does not enforce POSIX identity.
- Replication (`oci_file_storage_replication`) exists but is not instantiated by
  default.
- The module owns an **empty** NSG (`create_nsg`, default true) that the
  security-rules module populates — a mount target with no NSG is unreachable,
  so this fails closed. Export defaults are pinned (`access = READ_WRITE`,
  `identity_squash = NONE`) rather than inherited, because OCI's own default
  (`identity_squash = ROOT`) is stricter than the current behaviour elsewhere.