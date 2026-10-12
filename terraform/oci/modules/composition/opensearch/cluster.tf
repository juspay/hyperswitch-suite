# =============================================================================
# OCI Search with OpenSearch - the managed cluster (check sheet features 1-13)
# =============================================================================
# THIS MODULE IS NOT A VM TIER, AND THAT IS THE WHOLE POINT.
#
# Read the AWS module, not the filename pattern it shares with kafka, cassandra
# and clickhouse: it contains no aws_instance, no aws_network_interface and no
# EBS volume. It wraps terraform-aws-modules/opensearch/aws, which emits a single
# aws_opensearch_domain - Amazon's fully managed service. So the OCI question was
# never "how do we self-manage search on Compute", it was "does OCI have a
# matching managed service", and the answer is yes: OCI Search with OpenSearch,
# one resource, available in all OCI commercial regions.
#
# THE GCP PORT IS A FALSE FRIEND HERE. GCP's branch runs OpenSearch on a Compute
# Engine node fleet, and its own header comment says why: "GCP has no first-party
# managed OpenSearch/Elasticsearch service". GCP was FORCED to downgrade a managed
# AWS feature. OCI is not in that position, and copying GCP's architecture would
# be accepting a regression neither AWS nor OCI's platform requires. There is
# deliberately no compute, storage, static-addressing or image-pipeline
# scaffolding anywhere in this module.
#
# vm-tier-and-images.md section 1 already records this correction: treat the
# originating brief's "eight VM-tier modules" as seven plus one mis-filed
# managed-service module. Any downstream dependency phasing that assumed
# otherwise is a framework.md section 4.6 gate item.
#
# -----------------------------------------------------------------------------
# WHAT THE SCHEMA READ SETTLED, AND WHAT IT DID NOT
# -----------------------------------------------------------------------------
# Read from oracle/oci 9.0.0's own JSON schema in-session, so these are facts
# about the provider rather than inferences:
#
#   CONFIRMED PRESENT: nsg_id (single, not a list), subnet_id (single, required),
#     vcn_compartment_id / subnet_compartment_id (both required), security_mode /
#     security_master_user_name / security_master_user_password_hash,
#     certificate_config, maintenance_details.notification_email_ids, six
#     independently sized node tiers, opensearch_fqdn / opendashboard_fqdn /
#     opensearch_private_ip / opendashboard_private_ip / total_storage_gb.
#
#   CONFIRMED ABSENT - these are now real gaps, not unverified ones:
#     * no IOPS or throughput argument (AWS ebs_options.iops / .throughput).
#       Feature 4, PARTIAL, check sheet 4.2 - open question 9.1 now CLOSED as a
#       confirmed gap: storage performance follows node shape, full stop.
#     * no customer-managed-key argument for encryption at rest (AWS
#       encrypt_at_rest.kms_key_id) and no node_to_node_encryption toggle.
#       Feature 5, PARTIAL, check sheet 4.3 - open question 9.2 now CLOSED as a
#       confirmed gap. Encryption is whatever Oracle does by default and there is
#       no lever. If a customer-managed key is a hard compliance requirement for
#       this data classification, THAT IS A BLOCKER, and it needs its own gate
#       item now that it is confirmed rather than suspected.
#     * no log_publishing_options equivalent (AWS ES_APPLICATION_LOGS,
#       INDEX_SLOW_LOGS, SEARCH_SLOW_LOGS, AUDIT_LOGS -> CloudWatch). Feature 9,
#       PARTIAL, check sheet 4.5 - open question 9.3 now CLOSED as a confirmed
#       gap on THIS resource. Whether a Service Connector Hub pipeline can carry
#       these logs is a separate, still-open question; there is no first-class
#       argument. Slow-query and AUDIT logging are therefore not available from
#       Terraform today, which matters for the PCI-DSS-adjacent posture elsewhere
#       in this programme.
#     * availability_domains is a COMPUTED attribute, not an input. AWS's
#       zone_awareness_enabled / availability_zone_count /
#       multi_az_with_standby_enabled have nothing to map to, and ap-mumbai-1 has
#       one AD anyway. Feature 3, PARTIAL, check sheet 4.1. Unlike the
#       self-managed modules in this wave, there is not even a fault_domain lever
#       here - placement is entirely Oracle's, so "it's managed, so it's someone
#       else's problem" is true right up until it is the reason for an outage.
#
# MANDATORY TIERS: master_node_* and opendashboard_node_* are REQUIRED arguments.
# AWS's dedicated_master_enabled = false has no counterpart - there is no
# no-dedicated-master configuration, and Dashboards is separately sized rather
# than free with the domain. Every environment, including dev, pays for both.
#
# BACKUPS (feature 13) are a platform guarantee with no Terraform surface, the
# same implicit shape as Amazon OpenSearch Service's automated snapshots.

resource "oci_opensearch_opensearch_cluster" "this" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  software_version = var.software_version

  # ---------------------------------------------------------------------------
  # Network
  # ---------------------------------------------------------------------------
  vcn_id                = var.vcn_id
  vcn_compartment_id    = local.vcn_compartment_id
  subnet_id             = var.subnet_id
  subnet_compartment_id = local.subnet_compartment_id

  # Exactly one. See network.tf.
  nsg_id = local.nsg_id

  # ---------------------------------------------------------------------------
  # Data tier (feature 1)
  # ---------------------------------------------------------------------------
  data_node_count           = var.data_node_count
  data_node_host_type       = var.data_node_host_type
  data_node_host_ocpu_count = var.data_node_host_ocpu_count
  data_node_host_memory_gb  = var.data_node_host_memory_gb
  data_node_storage_gb      = var.data_node_storage_gb
  data_node_host_shape      = var.data_node_host_shape

  # ---------------------------------------------------------------------------
  # Master / leader tier (feature 2) - REQUIRED, unlike AWS
  # ---------------------------------------------------------------------------
  master_node_count           = var.master_node_count
  master_node_host_type       = var.master_node_host_type
  master_node_host_ocpu_count = var.master_node_host_ocpu_count
  master_node_host_memory_gb  = var.master_node_host_memory_gb
  master_node_host_shape      = var.master_node_host_shape

  # ---------------------------------------------------------------------------
  # Dashboards tier (feature 11) - REQUIRED, no AWS counterpart argument
  # ---------------------------------------------------------------------------
  opendashboard_node_count           = var.opendashboard_node_count
  opendashboard_node_host_ocpu_count = var.opendashboard_node_host_ocpu_count
  opendashboard_node_host_memory_gb  = var.opendashboard_node_host_memory_gb
  opendashboard_node_host_shape      = var.opendashboard_node_host_shape

  # ---------------------------------------------------------------------------
  # Optional tiers with no AWS analogue - all off by default
  # ---------------------------------------------------------------------------
  # Not enabled speculatively. AWS's warm_enabled / warm_type / warm_count
  # (UltraWarm) are deliberately NOT mapped onto search or ml nodes: those are
  # different things, and approximating one with the other would be exactly the
  # "two service names rhyme" mistake the framework warns about.
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

  # ---------------------------------------------------------------------------
  # Fine-grained access control (feature 6)
  # ---------------------------------------------------------------------------
  # Note the input-shape difference: a password HASH, not a plaintext password
  # and not an IAM ARN. No credential is generated, logged or defaulted here.
  security_mode                      = var.security_mode
  security_master_user_name          = var.security_master_user_name
  security_master_user_password_hash = var.security_master_user_password_hash

  # ---------------------------------------------------------------------------
  # Custom endpoint certificates (feature 7)
  # ---------------------------------------------------------------------------
  dynamic "certificate_config" {
    for_each = var.certificate_config != null ? [var.certificate_config] : []
    content {
      cluster_certificate_mode             = certificate_config.value.cluster_certificate_mode
      dashboard_certificate_mode           = certificate_config.value.dashboard_certificate_mode
      open_search_api_certificate_id       = certificate_config.value.open_search_api_certificate_id
      open_search_dashboard_certificate_id = certificate_config.value.open_search_dashboard_certificate_id
    }
  }

  # ---------------------------------------------------------------------------
  # Maintenance (SUBSTITUTE, feature 8)
  # ---------------------------------------------------------------------------
  # A notification channel, not a schedule. See
  # var.maintenance_notification_email_ids for the five AWS variables this one
  # argument replaces and why they are dropped rather than approximated.
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
