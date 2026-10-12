# =============================================================================
# General configuration
# =============================================================================

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string

  validation {
    condition     = contains(["dev", "integ", "prod", "sandbox"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod, sandbox"
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

variable "compartment_id" {
  description = "OCID of the compartment file systems, mount target and snapshot policies are created in"
  type        = string

  validation {
    condition     = startswith(var.compartment_id, "ocid1.compartment.") || startswith(var.compartment_id, "ocid1.tenancy.")
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment... or ocid1.tenancy...)."
  }
}

# Region passed through to outputs (no File Storage resource exposes a region
# attribute, so it has to be carried).
variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1). Output-only."
  type        = string
}

# Availability domain placement

variable "tenancy_ocid" {
  description = "Tenancy OCID used for the availability-domain lookup (null falls back to compartment_id; the ADs data source accepts either but returns the tenancy's list)"
  type        = string
  default     = null
}

variable "availability_domain" {
  description = "Explicit availability domain NAME (e.g. \"AbCd:AP-MUMBAI-1-AD-1\"). null selects by availability_domain_number instead."
  type        = string
  default     = null
}

variable "availability_domain_number" {
  description = "1-based index into the region's availability domains, used when availability_domain is null. 1 is the only valid value in a single-AD region such as ap-mumbai-1."
  type        = number
  default     = 1

  validation {
    condition     = var.availability_domain_number >= 1
    error_message = "availability_domain_number is 1-based and must be >= 1."
  }
}

# Mount target - the network attachment point
# ONE mount target, not a map: OCI subnets are regional (nothing to fan out
# across) and bandwidth is a mount-target-level property shared by every file
# system exported through it. A caller needing a second, independently-throttled
# mount target instantiates the module again.

variable "create_mount_target" {
  description = "Create a mount target. false requires existing_mount_target_id and existing_export_set_id."
  type        = bool
  default     = true
}

variable "mount_target_subnet_id" {
  description = "OCID of the private subnet the mount target's VNICs land in. Singular, not a list - see the comment above. Required when create_mount_target = true."
  type        = string
  default     = null
}

# This module owns the mount target NSG (rather than accepting a pre-existing
# one): vpc-network strips the VCN default security list to zero rules, so an
# NSG-less mount target is unreachable and every NFS mount fails. The NSG is
# created EMPTY - an empty NSG denies everything, so the failure direction is
# safe.

variable "create_nsg" {
  description = "Create an empty NSG for the mount target for security-rules to populate. Requires vcn_id. An empty NSG denies all traffic, so nothing can mount until security-rules adds NFS rules - that is deliberate."
  type        = bool
  default     = true
}

variable "vcn_id" {
  description = "OCID of the VCN the NSG is created in. Required when create_nsg = true."
  type        = string
  default     = null
}

variable "mount_target_nsg_ids" {
  description = "ADDITIONAL pre-existing NSG OCIDs to attach to the mount target, beyond the module-owned one. Combined total must not exceed 5."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.mount_target_nsg_ids) <= 5
    error_message = "An OCI mount target accepts at most 5 NSGs."
  }
}

variable "mount_target_display_name" {
  description = "Display name for the mount target (null derives one from project/environment)"
  type        = string
  default     = null
}

variable "mount_target_hostname_label" {
  description = "DNS hostname label for the mount target, giving it an FQDN inside the VCN. Optional on OCI."
  type        = string
  default     = null
}

variable "mount_target_ip_address" {
  description = "Fixed private IP for the mount target (null lets OCI allocate). Counterpart of AWS's per-mount-target ip_address."
  type        = string
  default     = null
}

# AWS ties throughput to the FILE SYSTEM (elastic, auto-scaling); OCI ties it to
# the MOUNT TARGET, from a fixed tier ladder shared by every file system behind
# it, with no elastic mode. Upgrade carries a 30-day billing commitment. null
# keeps the Standard tier.
variable "mount_target_requested_throughput" {
  description = "Mount-target bandwidth tier in Gbps (e.g. \"1\", \"20\", \"40\"). null = Standard. NOT a per-file-system elastic knob - every file system behind this mount target shares the ceiling. Changing tiers is a capacity-planning action, not a variable flip."
  type        = string
  default     = null
}

variable "existing_mount_target_id" {
  description = "OCID of a pre-existing mount target to export through, when create_mount_target = false"
  type        = string
  default     = null
}

variable "existing_export_set_id" {
  description = "OCID of the pre-existing mount target's export set, when create_mount_target = false. An export set is created implicitly with each mount target and cannot be created independently - see main.tf."
  type        = string
  default     = null
}

# =============================================================================
# File systems
# =============================================================================

variable "file_systems" {
  description = <<-EOT
    Map of file-system key to configuration, mirroring the AWS module's
    `for_each = var.file_systems`. Every AWS live root provisions exactly one
    entry, keyed `superposition-backup`.

    Deliberately ABSENT compared with the AWS surface, each a recorded gap:
      - performance_mode     no OCI counterpart (generalPurpose/maxIO). Zero
                             blast radius: no live root sets anything but the
                             AWS default.
      - throughput_mode /
        provisioned_throughput_in_mibps
                             feature 2, PARTIAL. Moved to the mount target; see
                             mount_target_requested_throughput.
      - encrypted (bool)     encryption is not optional on OCI, so there is no
                             on/off flag to port. kms_key_id below is the whole
                             decision (feature 3, FULL).
      - lifecycle_policy     feature 4, NONE. No IA/Archive storage class exists.
      - access_points        feature 9, SUBSTITUTE. Approximated with one export
                             per path; no POSIX-enforcing resource exists.
      - file_system_policy   feature 10, SUBSTITUTE. Moves to a compartment-level
                             IAM policy authored outside this module.
      - replication_configuration / replication_overwrite_protection
                             feature 11, FULL but unused in every live root
                             (replication_configuration = null everywhere). Not
                             carried into the first cut; oci_file_storage_replication
                             exists when a real consumer appears.
  EOT

  type = map(object({
    display_name = optional(string)

    # Encryption is always on with no plaintext mode; null = Oracle-managed key.
    kms_key_id = optional(string)

    # The export path inside the file system, e.g. "/superposition-backup".
    # This, the mount target IP and the file-system OCID are the three parts of
    # the OKE CSI driver's static volumeHandle.
    path = optional(string)

    # Export-options defaults are pinned in locals.tf, not inherited from OCI:
    # OCI defaults identity_squash to ROOT, which is STRICTER than the current
    # AWS behaviour and would be a silent change on port.
    export_options = optional(list(object({
      source                         = string
      access                         = optional(string)
      identity_squash                = optional(string)
      anonymous_uid                  = optional(string)
      anonymous_gid                  = optional(string)
      require_privileged_source_port = optional(bool)
      is_anonymous_access_allowed    = optional(bool)
      # Kerberos auth-type gating (KRB5/KRB5I/KRB5P).
      allowed_auth = optional(list(string))
    })))

    # Snapshot policy - the backup/retention mechanism; File-Storage-scoped, no
    # cross-service backup view.
    snapshot_policy = optional(object({
      display_name  = optional(string)
      policy_prefix = optional(string)
      schedules = list(object({
        period                        = string # HOURLY | DAILY | WEEKLY | MONTHLY | YEARLY
        time_zone                     = optional(string)
        hour_of_day                   = optional(number)
        day_of_week                   = optional(string)
        day_of_month                  = optional(number)
        month                         = optional(string)
        schedule_prefix               = optional(string)
        time_schedule_start           = optional(string)
        retention_duration_in_seconds = optional(string)
      }))
    }))

    freeform_tags = optional(map(string), {})
    defined_tags  = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for k, v in var.file_systems : alltrue([
        for o in coalesce(v.export_options, []) :
        o.access == null || contains(["READ_WRITE", "READ_ONLY", "NONE"], o.access)
      ])
    ])
    error_message = "export_options.access must be one of READ_WRITE, READ_ONLY, NONE."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems : alltrue([
        for o in coalesce(v.export_options, []) :
        o.identity_squash == null || contains(["NONE", "ROOT", "ALL"], o.identity_squash)
      ])
    ])
    error_message = "export_options.identity_squash must be one of NONE, ROOT, ALL."
  }

  validation {
    condition = alltrue([
      for k, v in var.file_systems :
      v.snapshot_policy == null || length(try(v.snapshot_policy.schedules, [])) > 0
    ])
    error_message = "A snapshot_policy must define at least one schedule; an empty policy backs nothing up."
  }
}

# Applied to every export that does not set its own export_options.
variable "default_export_source_cidr" {
  description = "CIDR allowed to mount when a file system defines no export_options of its own. Defaults to the RFC1918 supernet the VCN sits inside; narrow it per environment."
  type        = string
  default     = "10.0.0.0/8"
}

# =============================================================================
# Tagging
# =============================================================================

variable "freeform_tags" {
  description = "Freeform tags merged onto every resource (AWS `tags` / GCP `labels` analogue)"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Requires the tag namespace to already exist in the tenancy."
  type        = map(string)
  default     = {}
}
