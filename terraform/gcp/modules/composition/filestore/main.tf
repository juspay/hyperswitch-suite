# ============================================================================
# Filestore (GCP equivalent of composition/efs)
# ============================================================================
# No official terraform-google-modules/GoogleCloudPlatform registry module
# covers Filestore, so this module wraps the raw resource directly, keeping
# the same for_each-over-file-systems shape as the AWS efs module: one map
# entry in, one Filestore instance out. Mount targets are implicit on GCP
# (an instance's fileShares are reachable directly on its VPC IP - there is
# no separate "mount target" resource the way EFS has), and access points
# become NFS shares within an instance.
#
# Usage:
#   module "filestore" {
#     source = "../../modules/composition/filestore"
#
#     project_id  = "hyperswitch-dev"
#     environment = "dev"
#
#     instances = {
#       shared = {
#         zone     = "europe-west1-b"
#         network  = module.vpc_network.network_self_link
#         capacity_gb = 1024
#         shares      = [{ name = "shared", capacity_gb = 1024 }]
#       }
#     }
#   }
# ============================================================================

resource "google_filestore_instance" "this" {
  for_each = var.instances

  project     = var.project_id
  name        = "${local.name_prefix}-${each.key}"
  location    = each.value.zone
  tier        = coalesce(each.value.tier, "BASIC_HDD")
  description = try(each.value.description, "Hyperswitch ${each.key} Filestore instance")

  dynamic "file_shares" {
    for_each = each.value.shares
    content {
      name        = file_shares.value.name
      capacity_gb = file_shares.value.capacity_gb

      dynamic "nfs_export_options" {
        for_each = try(file_shares.value.nfs_export_options, [])
        content {
          ip_ranges   = nfs_export_options.value.ip_ranges
          access_mode = try(nfs_export_options.value.access_mode, "READ_WRITE")
          squash_mode = try(nfs_export_options.value.squash_mode, "NO_ROOT_SQUASH")
        }
      }
    }
  }

  networks {
    network           = each.value.network
    modes             = ["MODE_IPV4"]
    connect_mode      = try(each.value.connect_mode, "DIRECT_PEERING")
    reserved_ip_range = try(each.value.reserved_ip_range, null)
  }

  kms_key_name = try(each.value.kms_key_name, null)

  labels = merge(local.common_labels, try(each.value.labels, {}))
}

resource "google_filestore_backup" "this" {
  for_each = { for k, v in var.instances : k => v if try(v.create_backup, false) }

  project           = var.project_id
  name              = "${local.name_prefix}-${each.key}-backup"
  location          = try(each.value.backup_region, each.value.zone)
  source_instance   = google_filestore_instance.this[each.key].id
  source_file_share = each.value.shares[0].name

  labels = local.common_labels
}
