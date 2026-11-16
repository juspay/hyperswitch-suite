locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # AD selection. Explicit name wins; otherwise index into the region's list.
  # In a single-AD region such as ap-mumbai-1 there is exactly one element and
  # the index is decorative - kept anyway so the module ports unchanged to a
  # multi-AD region without a variable-surface change.
  availability_domain = (
    var.availability_domain != null
    ? var.availability_domain
    : data.oci_identity_availability_domains.this[0].availability_domains[var.availability_domain_number - 1].name
  )

  freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "file-storage"
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # The module-owned NSG plus any additional pre-existing ones.
  all_nsg_ids = concat(
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : [],
    var.mount_target_nsg_ids,
  )

  # The export set is created implicitly with the mount target and is not
  # independently creatable (oci_file_storage_export_set requires a
  # mount_target_id and has every other attribute computed - verified against
  # the oracle/oci 9.0.0 schema). This resolves check sheet open question 1:
  # this module manages TWO resources plus exports, not three.
  export_set_id = (
    var.create_mount_target
    ? try(oci_file_storage_mount_target.this[0].export_set_id, null)
    : var.existing_export_set_id
  )

  mount_target_id = (
    var.create_mount_target
    ? try(oci_file_storage_mount_target.this[0].id, null)
    : var.existing_mount_target_id
  )

  mount_target_ip = (
    var.create_mount_target
    ? try(oci_file_storage_mount_target.this[0].ip_address, null)
    : null
  )

  # ---------------------------------------------------------------------------
  # Export options defaulting - feature 7.
  #
  # The AWS module exposes NO NFS export-options surface: client control there is
  # entirely network-layer security-group rules. So there is nothing to port and
  # a default has to be chosen. It is chosen here rather than left to OCI,
  # because OCI's own default is identity_squash = ROOT, which is STRICTER than
  # the effective AWS posture (open within the VPC, root preserved) and would be
  # a silent behaviour change dressed up as a port.
  #
  # access = READ_WRITE, identity_squash = NONE reproduces today's AWS behaviour.
  # It is deliberately not tightened here: tightening it would be a security
  # improvement, but an undeclared one, and the place to make it is the unit or
  # the stack, visibly.
  # ---------------------------------------------------------------------------
  default_export_options = [{
    source                         = var.default_export_source_cidr
    access                         = "READ_WRITE"
    identity_squash                = "NONE"
    anonymous_uid                  = null
    anonymous_gid                  = null
    require_privileged_source_port = null
    is_anonymous_access_allowed    = null
    allowed_auth                   = null
  }]

  file_systems = {
    for key, cfg in var.file_systems : key => {
      display_name  = cfg.display_name != null ? cfg.display_name : "${local.name_prefix}-${key}"
      kms_key_id    = cfg.kms_key_id
      path          = cfg.path != null ? cfg.path : "/${key}"
      freeform_tags = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags  = merge(var.defined_tags, cfg.defined_tags)

      export_options = (
        cfg.export_options != null && length(coalesce(cfg.export_options, [])) > 0
        ? [for o in cfg.export_options : {
          source                         = o.source
          access                         = o.access != null ? o.access : "READ_WRITE"
          identity_squash                = o.identity_squash != null ? o.identity_squash : "NONE"
          anonymous_uid                  = o.anonymous_uid
          anonymous_gid                  = o.anonymous_gid
          require_privileged_source_port = o.require_privileged_source_port
          is_anonymous_access_allowed    = o.is_anonymous_access_allowed
          allowed_auth                   = o.allowed_auth
        }]
        : local.default_export_options
      )
    }
  }

  # Only file systems that asked for one. Mirrors AWS's enable_backup_policy
  # gate rather than creating a policy nobody wired up.
  snapshot_policies = {
    for key, cfg in var.file_systems : key => cfg.snapshot_policy
    if cfg.snapshot_policy != null
  }

  # The OKE CSI driver's static-provisioning volumeHandle:
  #   <FileSystemOCID>:<MountTargetIP>:<path>
  # (confirmed in the check sheet's section 7 smoke-test note against
  # docs.oracle.com/.../contengcreatingpersistentvolumeclaim_Provisioning_PVCs_on_FSS.htm).
  # Emitted as an output because assembling it by hand from three separate
  # outputs is exactly the sort of thing that gets a colon wrong at 2am.
  csi_volume_handles = {
    for key, fs in oci_file_storage_file_system.this :
    key => "${fs.id}:${local.mount_target_ip}:${local.file_systems[key].path}"
  }
}
