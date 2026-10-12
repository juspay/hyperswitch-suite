# Output contract. AWS outputs with no OCI equivalent (ARNs, DNS names, access
# points) are dropped rather than faked. Mount target IPs come from the
# resource's own ip_address, not a data lookup - the proposed lookup is
# unbuildable (private_ip_ids is computed, so a for_each over it is unknown at
# plan time).

output "file_system_ids" {
  description = "Map of file-system key to OCID. Plays the role of both AWS's file_system_ids and file_system_arns."
  value       = { for k, v in oci_file_storage_file_system.this : k => v.id }
}

output "file_system_display_names" {
  description = "Map of file-system key to display name"
  value       = { for k, v in oci_file_storage_file_system.this : k => v.display_name }
}

output "mount_target_id" {
  description = "OCID of the mount target (created here, or the pre-existing one supplied). Singular, where AWS returns a map keyed by subnet - OCI subnets are regional, so there is one."
  value       = local.mount_target_id

  # Cross-variable checks - at plan time, not at minute 20 of an API call.
  precondition {
    condition     = !var.create_mount_target || var.mount_target_subnet_id != null
    error_message = "mount_target_subnet_id is required when create_mount_target = true - an OCI mount target's VNICs must land in a subnet."
  }

  precondition {
    condition     = var.create_mount_target || (var.existing_mount_target_id != null && var.existing_export_set_id != null)
    error_message = "create_mount_target = false requires BOTH existing_mount_target_id and existing_export_set_id. An export set cannot be created independently, so it has to be supplied alongside the mount target that owns it."
  }

  precondition {
    condition     = length(var.file_systems) == 0 || var.create_mount_target || var.existing_export_set_id != null
    error_message = "There is nowhere to export these file systems: no mount target is being created and no existing export set was supplied."
  }

  precondition {
    condition     = !var.create_nsg || var.vcn_id != null
    error_message = "vcn_id is required when create_nsg = true - oci_core_network_security_group is created inside a VCN."
  }

  precondition {
    condition     = length(local.all_nsg_ids) <= 5
    error_message = "An OCI mount target accepts at most 5 NSGs, and the module-owned one counts. Reduce mount_target_nsg_ids or set create_nsg = false."
  }

  precondition {
    condition     = !var.create_mount_target || length(local.all_nsg_ids) > 0
    error_message = "The mount target would have no NSG. vpc-network manages the VCN's default security list down to zero rules, so an NSG-less mount target is unreachable and every NFS mount fails. Set create_nsg = true or supply mount_target_nsg_ids."
  }
}

output "mount_target_export_set_id" {
  description = "OCID of the mount target's implicitly-created export set. No AWS counterpart; exports attach to this rather than to the file system."
  value       = local.export_set_id
}

output "mount_target_ip_address" {
  description = "Primary private IP of the mount target - what an NFS client and the OKE CSI driver's volumeHandle address. Replaces AWS's mount_target_ip_addresses map."
  value       = local.mount_target_ip
}

output "mount_target_private_ip_ids" {
  description = "OCIDs of the private IPs the mount target reserves. Counterpart of AWS's mount_target_network_interface_ids, but a LIST: an OCI mount target reserves 3 IPs where an EFS mount target has 1 ENI."
  value       = try(oci_file_storage_mount_target.this[0].private_ip_ids, [])
}

output "mount_target_hostname_label" {
  description = "DNS hostname label of the mount target, or null. Counterpart of AWS's mount_target_dns_names, but optional - an OCI mount target has no FQDN unless one is asked for."
  value       = try(oci_file_storage_mount_target.this[0].hostname_label, null)
}

output "mount_target_availability_domain" {
  description = "Availability domain the mount target and file systems live in. Counterpart of AWS's mount_target_availability_zones - singular, because there is one mount target."
  value       = local.availability_domain
}

output "nsg_id" {
  description = "OCID of the module-owned, deliberately EMPTY NSG on the mount target, or null. This is what security-rules writes NFS rules into - the same contract database and oci-cache-valkey expose. Nothing can mount until those rules exist."
  value       = try(oci_core_network_security_group.this[0].id, null)
}

output "nsg_ids" {
  description = "All NSG OCIDs attached to the mount target (module-owned plus any supplied). Counterpart of AWS's security_group_ids."
  value       = local.all_nsg_ids
}

output "export_ids" {
  description = "Map of file-system key to export OCID"
  value       = { for k, v in oci_file_storage_export.this : k => v.id }
}

output "export_paths" {
  description = "Map of file-system key to export path"
  value       = { for k, v in oci_file_storage_export.this : k => v.path }
}

output "snapshot_policy_ids" {
  description = "Map of file-system key to snapshot-policy OCID, for the file systems that requested one. Feature 5's SUBSTITUTE for AWS Backup - File-Storage-scoped, with no cross-service backup view."
  value       = { for k, v in oci_file_storage_filesystem_snapshot_policy.this : k => v.id }
}

# The one output the kubernetes-resources layer needs: the OKE FSS CSI driver's
# static-provisioning volumeHandle, `<FileSystemOCID>:<MountTargetIP>:<path>`.
# accessModes must be ReadWriteMany.
output "csi_volume_handles" {
  description = "Map of file-system key to the fss.csi.oraclecloud.com static volumeHandle (<FileSystemOCID>:<MountTargetIP>:<path>)"
  value       = local.csi_volume_handles
}

output "region" {
  description = "OCI region identifier, passed through (no File Storage resource exposes a region attribute)"
  value       = var.region
}
