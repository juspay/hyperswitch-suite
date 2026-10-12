# File Storage - the OCI counterpart of aws efs / gcp filestore. This module
# stops at the storage layer; mounting into a pod is the CSI driver's job.

# Availability domains are a tenancy-level listing. Only queried when the caller
# did not name an AD explicitly.
data "oci_identity_availability_domains" "this" {
  count = var.availability_domain == null ? 1 : 0

  compartment_id = var.tenancy_ocid != null ? var.tenancy_ocid : var.compartment_id
}

# Module-owned NSG - created EMPTY; security-rules (phase 5) writes the NFS
# rules into it. An empty NSG denies everything, so an unpopulated one fails
# closed.
resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-fss-mt-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# Mount target - ONE where AWS builds one per AZ. OCI subnets are regional and
# ap-mumbai-1 has a single AD, so there is no multi-mount-target redundancy to
# produce here.
resource "oci_file_storage_mount_target" "this" {
  count = var.create_mount_target ? 1 : 0

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  subnet_id           = var.mount_target_subnet_id

  display_name = var.mount_target_display_name != null ? var.mount_target_display_name : "${local.name_prefix}-mt"

  # Optional on OCI - an FQDN exists only if a hostname label is set, which is
  # why the CSI volumeHandle addresses the mount target by IP rather than name.
  hostname_label = var.mount_target_hostname_label
  ip_address     = var.mount_target_ip_address

  nsg_ids = local.all_nsg_ids

  # A MOUNT-TARGET-level ceiling shared by every file system exported through
  # it, not AWS's per-file-system elastic auto-scaling. See the variable's
  # comment for why changing this is a capacity-planning action.
  requested_throughput = var.mount_target_requested_throughput

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # kerberos {} and ldap_idmap {} are NOT set here, deliberately. They are
  # mount-target-WIDE and are the only mechanism enforcing a mapped POSIX
  # identity; wiring one consumer would silently change identity handling for all
  # of them, which is the residual risk the check sheet records. Not exposed
  # until a real consumer needs it and the trade is made explicitly.
}

# WHAT IS NOT HERE: oci_file_storage_export_set. It requires mount_target_id and
# every other attribute is computed - it only tunes an export set the mount
# target already created implicitly, so this module reads
# mount_target.export_set_id instead of managing a resource.

# Snapshot policies - the SUBSTITUTE for AWS Backup (File-Storage-scoped, no
# cross-service view). Created per file system so retention can differ per
# workload.
resource "oci_file_storage_filesystem_snapshot_policy" "this" {
  for_each = local.snapshot_policies

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id

  display_name  = each.value.display_name != null ? each.value.display_name : "${local.name_prefix}-${each.key}-snapshots"
  policy_prefix = each.value.policy_prefix

  dynamic "schedules" {
    for_each = each.value.schedules

    content {
      period    = schedules.value.period
      time_zone = schedules.value.time_zone != null ? schedules.value.time_zone : "UTC"

      hour_of_day  = schedules.value.hour_of_day
      day_of_week  = schedules.value.day_of_week
      day_of_month = schedules.value.day_of_month
      month        = schedules.value.month

      schedule_prefix     = schedules.value.schedule_prefix
      time_schedule_start = schedules.value.time_schedule_start

      # Retention unit is SECONDS (vs days on the AWS backup-plan lifecycle); left as
      # the caller's value so the number in the stack is the number in the API.
      retention_duration_in_seconds = schedules.value.retention_duration_in_seconds
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# File systems
resource "oci_file_storage_file_system" "this" {
  for_each = local.file_systems

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = each.value.display_name

  # Encryption is always on with no plaintext mode; null = Oracle-managed key.
  kms_key_id = each.value.kms_key_id

  filesystem_snapshot_policy_id = try(oci_file_storage_filesystem_snapshot_policy.this[each.key].id, null)

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags

  # No lifecycle tiering (IA/archive): OCI File Storage has no lower-cost
  # storage class, so every byte bills at standard rate.
  #
  # No file_system_policy: OCI authorises compartment-level IAM policies, not
  # per-file-system resource policies.
}

# Exports - one per file system, on the shared mount target. Export options
# defaults are pinned in locals.tf, not inherited from OCI.
resource "oci_file_storage_export" "this" {
  for_each = local.file_systems

  export_set_id  = local.export_set_id
  file_system_id = oci_file_storage_file_system.this[each.key].id
  path           = each.value.path

  dynamic "export_options" {
    for_each = each.value.export_options

    content {
      source                         = export_options.value.source
      access                         = export_options.value.access
      identity_squash                = export_options.value.identity_squash
      anonymous_uid                  = export_options.value.anonymous_uid
      anonymous_gid                  = export_options.value.anonymous_gid
      require_privileged_source_port = export_options.value.require_privileged_source_port
      is_anonymous_access_allowed    = export_options.value.is_anonymous_access_allowed
      allowed_auth                   = export_options.value.allowed_auth
    }
  }

  # One export per path approximates access points: it controls WHICH subdirectory
  # is visible but does NOT enforce a per-client POSIX identity (that would move to
  # the mount target's idmap_type/kerberos/ldap_idmap - a mount-target-wide
  # surface, so a mistake in one consumer can ripple to the others).
}
