# efs (OCI) → OCI File Storage Service (FSS)

OCI equivalent of `terraform/aws/modules/composition/efs`. Uses `oci_file_storage_file_system` +
`oci_file_storage_mount_target` + `oci_file_storage_export`. No verified registry module exists for OCI FSS -
raw `oci` provider resources.

## Key structural difference

EFS is **regional** — one file system, mount targets in every AZ you need, all sharing one namespace. OCI FSS
file systems are **availability-domain-local** — `oci_file_storage_file_system.availability_domain` is required,
and a file system created in one AD is only reachable (at low latency) from mount targets in/near that AD. If
workloads across multiple ADs need shared access to the same data, either:

- Use OCI's regional (not AD-local) file storage variant where available in the target region, or
- Provision one `file_systems` entry per AD and replicate/sync data between them, or
- Fall back to Object Storage (S3-equivalent) if the access pattern tolerates it.

Access Points (`aws_efs_access_point`, POSIX UID/GID scoping) have no direct OCI FSS equivalent — path-level
access is controlled via NFS export options (`oci_file_storage_export.export_options`) instead, not modeled here
beyond the default export.
