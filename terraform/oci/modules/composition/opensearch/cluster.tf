# OCI Search with OpenSearch - the managed cluster. This is NOT a VM tier: the
# AWS module it ports wraps terraform-aws-modules/opensearch/aws (a single managed
# `aws_opensearch_domain`), and OCI has a matching fully managed service, so a
# single `oci_opensearch_opensearch_cluster` replaces it. There is deliberately
# no compute / storage / addressing / image-pipeline scaffolding anywhere here.

# Schema facts established for oracle/oci 9.0.0 in-session:
#   CONFIRMED PRESENT: nsg_id (single), subnet_id (single, required), both
#     compartment args, security_mode + master-user name/hash, certificate_config,
#     maintenance notification email ids, six independently sized node tiers,
#     opensearch/dashboard FQDNs and private IPs, total_storage_gb.
#   CONFIRMED ABSENT (real gaps, not unverified):
#     * no IOPS/throughput knob - storage performance follows node shape.
#     * no customer-managed-key for at-rest encryption, and no node-to-node TLS
#       toggle - encryption is whatever Oracle does by default. If a CMEK is a
#       hard compliance requirement for this data, THAT IS A BLOCKER needing its
#       own gate item.
#     * no log_publishing_options equivalent - slow-query and AUDIT logging are
#       not reachable from Terraform today (matters for the PCI-DSS-adjacent
#       posture). Service Connector Hub as an alternative path is unexplored.
#     * availability_domains is COMPUTED, not configured; ap-mumbai-1 has one AD,
#       and there is not even a fault_domain lever - placement is Oracle's.
#   MANDATORY TIERS: master_node_* and opendashboard_node_* are REQUIRED arguments
#     (AWS's dedicated_master_enabled = false has no counterpart), so every
#     environment, dev included, pays for both.
#   BACKUPS are a platform guarantee with no Terraform surface.

resource "oci_opensearch_opensearch_cluster" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  software_version = var.software_version

  # Network
  vcn_id                = var.vcn_id
  vcn_compartment_id    = local.vcn_compartment_id
  subnet_id             = var.subnet_id
  subnet_compartment_id = local.subnet_compartment_id

  # Exactly one. See network.tf.
  nsg_id = local.nsg_id

  # Data tier
  data_node_count           = var.data_node_count
  data_node_host_type       = var.data_node_host_type
  data_node_host_ocpu_count = var.data_node_host_ocpu_count
  data_node_host_memory_gb  = var.data_node_host_memory_gb
  data_node_storage_gb      = var.data_node_storage_gb
  data_node_host_shape      = var.data_node_host_shape

  # Master / leader tier - REQUIRED, unlike AWS
  master_node_count           = var.master_node_count
  master_node_host_type       = var.master_node_host_type
  master_node_host_ocpu_count = var.master_node_host_ocpu_count
  master_node_host_memory_gb  = var.master_node_host_memory_gb
  master_node_host_shape      = var.master_node_host_shape

  # Dashboards tier - REQUIRED, no AWS counterpart argument
  opendashboard_node_count           = var.opendashboard_node_count
  opendashboard_node_host_ocpu_count = var.opendashboard_node_host_ocpu_count
  opendashboard_node_host_memory_gb  = var.opendashboard_node_host_memory_gb
  opendashboard_node_host_shape      = var.opendashboard_node_host_shape

  # Optional tiers - all off by default; OCI's extra search/coordinator/ml tiers
  # are deliberately NOT used to approximate AWS UltraWarm (different things).
  search_node_count           = var.search_node_count > 0 ? var.search_node_count : null
  search_node_host_ocpu_count = var.search_node_count > 0 ? var.search_node_host_ocpu_count : null
  search_node_host_memory_gb  = var.search_node_count > 0 ? var.search_node_host_memory_gb : null
  search_node_storage_gb      = var.search_node_count > 0 ? var.search_node_storage_gb : null

  coordinator_node_count           = var.coordinator_node_count > 0 ? var.coordinator_node_count : null
  coordinator_node_host_ocpu_count = var.coordinator_node_count > 0 ? var.coordinator_node_host_ocpu_count : null
  coordinator_node_host_memory_gb  = var.coordinator_node_count > 0 ? var.coordinator_node_host_memory_gb : null

  ml_node_count           = var.ml_node_count > 0 ? var.ml_node_count : null
  ml_node_host_ocpu_count = var.ml_node_count > 0 ? var.ml_node_host_ocpu_count : null
  ml_node_host_memory_gb  = var.ml_node_count > 0 ? var.ml_node_host_memory_gb : null
  ml_node_storage_gb      = var.ml_node_count > 0 ? var.ml_node_storage_gb : null

  # Fine-grained access control. Note the input-shape difference: a password HASH,
  # not a plaintext password and not an IAM ARN. No credential is generated,
  # logged or defaulted here.
  security_mode                      = var.security_mode
  security_master_user_name          = var.security_master_user_name
  security_master_user_password_hash = var.security_master_user_password_hash

  # Custom endpoint certificates
  dynamic "certificate_config" {
    for_each = var.certificate_config != null ? [var.certificate_config] : []
    content {
      cluster_certificate_mode             = certificate_config.value.cluster_certificate_mode
      dashboard_certificate_mode           = certificate_config.value.dashboard_certificate_mode
      open_search_api_certificate_id       = certificate_config.value.open_search_api_certificate_id
      open_search_dashboard_certificate_id = certificate_config.value.open_search_dashboard_certificate_id
    }
  }

  # Maintenance - a notification channel, not a schedule. See
  # var.maintenance_notification_email_ids for the AWS variables this replaces.
  dynamic "maintenance_details" {
    for_each = length(var.maintenance_notification_email_ids) > 0 ? [1] : []
    content {
      notification_email_ids = var.maintenance_notification_email_ids
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  depends_on = [oci_identity_policy.service]
}
