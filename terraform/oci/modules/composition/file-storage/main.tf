# =============================================================================
# File Storage - the OCI counterpart of aws/modules/composition/efs and
# gcp/modules/composition/filestore.
#
# Check sheet: hyperswitch-infra/docs/multi-cloud-parity/oci/modules/efs.md
# Parity headline recorded there: 7 FULL / 1 PARTIAL / 3 SUBSTITUTE / 1 NONE.
#
# Scope, identical on all three clouds: this module stops at the storage layer.
# Mounting the result into a pod is the CSI driver's job (fss.csi.oraclecloud.com
# on OKE, aws-efs-csi-driver on EKS), installed and configured in the
# kubernetes-resources layer, not here. What this module owes that layer is the
# volumeHandle - see the csi_volume_handles output.
# =============================================================================

# Availability domains are a tenancy-level listing. Only queried when the caller
# did not name an AD explicitly.
data "oci_identity_availability_domains" "this" {
  count = var.availability_domain == null ? 1 : 0

  compartment_id = var.tenancy_ocid != null ? var.tenancy_ocid : var.compartment_id
}

# -----------------------------------------------------------------------------
# Module-owned NSG - see the deviation note in variables.tf
# -----------------------------------------------------------------------------
# Created EMPTY. security-rules (phase 5) writes the NFS rules into it, the same
# split `database` and `oci-cache-valkey` use. An empty NSG denies everything, so
# an unpopulated one fails closed.
resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-fss-mt-nsg"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Mount target
# -----------------------------------------------------------------------------
# ONE mount target where AWS builds one per AZ. Not a simplification: OCI
# subnets are regional so there is no per-AZ fan-out to perform, and
# ap-mumbai-1 has a single availability domain, so there is no second AD to
# place a peer into. AWS's multi-AZ mount-target redundancy has no equivalent
# here and cannot be produced from this layer (check sheet feature 6 and open
# question 4). Recorded, not worked around.
resource "oci_file_storage_mount_target" "this" {
  count = var.create_mount_target ? 1 : 0

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  subnet_id           = var.mount_target_subnet_id

  display_name = var.mount_target_display_name != null ? var.mount_target_display_name : "${local.name_prefix}-mt"

  # Optional on OCI. AWS mount targets always have a DNS name; here an FQDN
  # exists only if a hostname label is set, which is why the CSI volumeHandle
  # below addresses the mount target by IP rather than by name.
  hostname_label = var.mount_target_hostname_label
  ip_address     = var.mount_target_ip_address

  # Feature 8, FULL. The capability lives directly on this resource and File
  # Storage mount targets are one of the NSG-supported resource types.
  nsg_ids = local.all_nsg_ids

  # Feature 2, PARTIAL. A MOUNT-TARGET-level ceiling shared by every file system
  # exported through it, not AWS's per-file-system elastic auto-scaling. See the
  # variable's comment for why changing this is a capacity-planning action.
  requested_throughput = var.mount_target_requested_throughput

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # ---------------------------------------------------------------------------
  # NOT SET HERE, deliberately: kerberos {} and ldap_idmap {}.
  #
  # These are the only OCI mechanism that enforces a mapped POSIX identity, and
  # they are the closest thing to AWS's access points (feature 9, SUBSTITUTE).
  # They are mount-target-WIDE - one Kerberos realm, one LDAP id map, shared by
  # every export on this mount target - where an EFS access point is a
  # self-contained per-consumer object. Wiring them for one consumer would
  # silently change identity handling for all of them, which is precisely the
  # residual risk the check sheet records. Not exposed until a real consumer
  # needs it and the trade is made explicitly.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# WHAT IS NOT HERE: oci_file_storage_export_set
#
# Check sheet section 5 listed it as a possible fourth managed resource and
# section 9's open question 1 asked whether it needs authoring. Answer, verified
# against the oracle/oci 9.0.0 schema: no. The resource requires mount_target_id
# and every other attribute (availability_domain, compartment_id, vcn_id, state)
# is computed - it exists to TUNE an export set that the mount target already
# created implicitly (max_fs_stat_bytes / max_fs_stat_files, i.e. what `df`
# reports), not to create one. This module reads the mount target's computed
# export_set_id instead. Open question 1: closed.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Snapshot policies - the SUBSTITUTE for AWS Backup (feature 5)
# -----------------------------------------------------------------------------
# AWS's enable_backup_policy = true / backup_policy_status = "ENABLED" enrols the
# file system in AWS Backup: a cross-service plan and vault covering EFS, RDS and
# everything else from one pane. OCI's equivalent is scoped to File Storage
# alone. Day-to-day recoverability is preserved - this is a real declarative
# schedule with real retention, closer in shape to AWS's snapshot_window /
# snapshot_retention_limit than OCI Cache's discrete manual backup resource
# turned out to be. What is lost is the single cross-service compliance view.
#
# Created per file system rather than shared, so retention can differ per
# workload the way it does per AWS Backup plan.
#
# Oracle gate item, check sheet section 8 item 2 - NOT YET CONSULTED.
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

      # AWS expresses retention in days (backup plan lifecycle); OCI in seconds.
      # Left as the caller's value rather than converted, so the number in the
      # stack is the number in the API.
      retention_duration_in_seconds = schedules.value.retention_duration_in_seconds
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# File systems
# -----------------------------------------------------------------------------
resource "oci_file_storage_file_system" "this" {
  for_each = local.file_systems

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = each.value.display_name

  # Feature 3, FULL. Direct analogue of AWS's kms_key_id. There is no
  # `encrypted` boolean to port: OCI File Storage has no plaintext mode, so the
  # only decision is who holds the key. null = Oracle-managed.
  kms_key_id = each.value.kms_key_id

  filesystem_snapshot_policy_id = try(oci_file_storage_filesystem_snapshot_policy.this[each.key].id, null)

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags

  # ---------------------------------------------------------------------------
  # FEATURE 4 - STORAGE-CLASS LIFECYCLE TIERING: NONE.
  #
  # There is no `lifecycle_policy` argument here because OCI File Storage has no
  # infrequent-access or archive storage class for file data - nothing resembling
  # transition_to_ia / transition_to_archive / transition_to_primary_storage_class
  # exists on this resource, and no File Storage documentation reviewed describes
  # a lower-cost tier for cold file data.
  #
  # This is an ACTIVELY USED AWS feature, not a dormant one: all six live roots
  # set transition_to_ia = "AFTER_30_DAYS" and
  # transition_to_primary_storage_class = "AFTER_1_ACCESS" today. On OCI every
  # byte bills at the standard rate forever.
  #
  # No like-for-like mitigation exists. Object Storage's auto_tiering could hold
  # genuinely cold data, but that is an architecture change (POSIX filesystem ->
  # object store), not a drop-in. For the one workload this module serves today
  # (Superposition's config backup, small and slow-growing) the cost delta is
  # expected to be small - EXPECTED, not measured: check sheet open question 2.
  #
  # Oracle gate item, check sheet section 8 item 1 - NOT YET CONSULTED.
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # FEATURE 10 - FILE-SYSTEM RESOURCE POLICY: SUBSTITUTE.
  #
  # No counterpart to AWS's file_system_policy (an inline JSON document attached
  # to the file system, naming an arbitrary principal). OCI authorises identities,
  # not resources: the equivalent grant is a compartment-scoped IAM policy naming
  # a group or dynamic group, authored outside this module - the same fork
  # container-registry's feature 6 hit, and the two should be gated together.
  #
  # Zero blast radius today: file_system_policy is null in every AWS live root
  # reviewed. Nothing is being dropped that is currently in use. Unlike
  # container-registry, no optional policy resource is offered here, because
  # there is no current consumer to shape it around and an unused, guessed-at
  # policy surface is worse than none.
  #
  # Oracle gate item, check sheet section 8 item 4 - NOT YET CONSULTED.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# Exports - one per file system, on the shared mount target
# -----------------------------------------------------------------------------
# Feature 7, FULL and richer than the AWS module, which exposes no NFS-level
# export controls at all (it reaches for security-group rules instead). See
# locals.tf for why the defaults are pinned here rather than inherited from OCI.
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

  # ---------------------------------------------------------------------------
  # FEATURE 9 - ACCESS POINTS: SUBSTITUTE, and this resource is the substitute.
  #
  # An EFS access point bundles an ENFORCED POSIX identity (posix_user), a root
  # directory with auto-create-on-first-mount semantics, and its own ARN a client
  # mounts directly. Nothing in OCI File Storage does all three.
  #
  # One export per path is the closest approximation: it controls WHICH
  # subdirectory is visible, but does NOT enforce a UID/GID override on write.
  # That enforcement, if ever needed, moves to the mount target's
  # idmap_type/kerberos/ldap_idmap - a shared, mount-target-wide surface, so a
  # mistake in one consumer's config can ripple to the others. Strictly weaker
  # than an access point's self-contained design.
  #
  # Zero blast radius today: access_points is {} in every AWS live root reviewed.
  # Oracle gate item, check sheet section 8 item 3 - NOT YET CONSULTED.
  # ---------------------------------------------------------------------------
}
