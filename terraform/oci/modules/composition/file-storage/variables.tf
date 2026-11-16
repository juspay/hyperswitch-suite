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

# Passed through to outputs. AWS's module reads its region back from
# data.aws_region.current; no OCI File Storage resource exposes a region
# attribute, so it has to be carried.
variable "region" {
  description = "OCI region identifier (e.g. ap-mumbai-1). Output-only."
  type        = string
}

# =============================================================================
# Availability domain placement
# =============================================================================
# AWS never asks for an AZ here: `mount_targets` is keyed by subnet id and the
# subnet carries the AZ. OCI makes it explicit on BOTH the file system and the
# mount target, because OCI subnets are regional and carry no AD (check sheet
# feature 6, and the same structural fork vpc-network already recorded).
#
# ap-mumbai-1 has exactly ONE availability domain. AWS's "one mount target per
# AZ" high-availability shape therefore has no counterpart here: there is one AD
# to place into, so there is one mount target. This is not a module limitation
# and it cannot be worked around from this layer. Check sheet open question 4.

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

# =============================================================================
# Mount target - the network attachment point
# =============================================================================
# Replaces AWS's `mount_targets` map (one entry per subnet/AZ) plus its whole
# security-group surface (create_security_group, security_group_vpc_id,
# security_group_ingress_rules, security_group_egress_rules).
#
# ONE mount target, not a map. Two reasons, both structural: OCI subnets are
# regional so there is nothing to fan out across, and mount-target bandwidth is
# a property of the MOUNT TARGET shared by every file system exported through it
# (check sheet feature 2, PARTIAL) - which makes "one mount target per file
# system" the recommended shape, matching this module's actual single-file-system
# usage. A caller needing a second, independently-throttled mount target
# instantiates the module again.

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

# -----------------------------------------------------------------------------
# DELIBERATE DEVIATION FROM THE CHECK SHEET, recorded rather than silent.
#
# efs.md section 5 proposed that this module create no NSG and accept only
# pre-existing OCIDs. That is not what the sibling wave-1 modules do: `database`
# and `oci-cache-valkey` both own an empty NSG and let `security-rules` (phase 5)
# write rules into it - and oci-cache-valkey's unit records that its original
# no-NSG design was found to be an inconsistency and corrected during assembly.
#
# Following the sheet literally here would be worse than inconsistent, it would
# be broken: vpc-network manages the VCN's default security list down to ZERO
# rules on purpose, so a mount target with no NSG has no path to it at all and
# every NFS mount fails. This module therefore owns an empty NSG by default and
# still accepts additional pre-existing ones.
#
# NSGs (never VCN security lists) is settled in
# hyperswitch-infra/docs/multi-cloud-parity/oci/network-security-model.md. What
# is NOT settled, and is not decided here, is the specific NFS rule set - that is
# security-rules' job and is oracle-gate pending (framework.md section 4.3).
# This module creates the NSG empty; an empty NSG denies everything, so the
# failure direction is safe.
# (Check sheet feature 8, FULL - the capability is on the resource.)
# -----------------------------------------------------------------------------
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
  description = "DNS hostname label for the mount target, giving it an FQDN inside the VCN. Optional on OCI, unlike AWS where every mount target always has a DNS name (check sheet output mapping)."
  type        = string
  default     = null
}

variable "mount_target_ip_address" {
  description = "Fixed private IP for the mount target (null lets OCI allocate). Counterpart of AWS's per-mount-target ip_address."
  type        = string
  default     = null
}

# Feature 2, PARTIAL - the most consequential shape change in this module.
# AWS ties throughput to the FILE SYSTEM (`throughput_mode = "elastic"` in every
# live root, which auto-scales per file system with no shared ceiling). OCI ties
# bandwidth to the MOUNT TARGET, from a fixed tier ladder, shared by every file
# system exported through it. There is no elastic mode. Upgrading a tier is not
# a same-day operation: High Performance tiers carry a 30-day billing commitment
# and cannot be created directly, only upgraded into from Standard.
# null keeps the Standard tier.
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

    # Feature 3, FULL. Direct analogue of AWS's kms_key_id. null = Oracle-managed
    # key; there is no plaintext mode to disable.
    kms_key_id = optional(string)

    # The export path inside the file system, e.g. "/superposition-backup".
    # This, the mount target IP and the file-system OCID are the three parts of
    # the OKE CSI driver's static volumeHandle.
    path = optional(string)

    # Feature 7, FULL and RICHER than AWS. This composition module has no
    # NFS-export-options surface at all on AWS - client control there is purely
    # network-layer security-group rules. Defaults below are set in locals.tf,
    # NOT left to OCI's own defaults: OCI defaults identity_squash to ROOT,
    # which is STRICTER than the current AWS behaviour and would be a silent
    # behaviour change on port.
    export_options = optional(list(object({
      source                         = string
      access                         = optional(string)
      identity_squash                = optional(string)
      anonymous_uid                  = optional(string)
      anonymous_gid                  = optional(string)
      require_privileged_source_port = optional(bool)
      is_anonymous_access_allowed    = optional(bool)
      # Kerberos auth-type gating (KRB5/KRB5I/KRB5P) with no AWS counterpart.
      allowed_auth = optional(list(string))
    })))

    # Feature 5, SUBSTITUTE. AWS's enable_backup_policy/backup_policy_status
    # hook the file system into AWS Backup, a cross-service plan/vault system.
    # OCI's equivalent is a File-Storage-only snapshot policy: same declarative
    # schedule + retention, no unified cross-service backup view.
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

# Applied to every export that does not set its own export_options. Pinned at
# the unit level rather than relied on from here - see the unit's comment.
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
