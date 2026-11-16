###############################################################################
# VCN flow logs
#
# FULL parity with AWS's aws_flow_log, via a different service. OCI flow logs
# are Logging-service objects, not VCN objects: a log group holds a log whose
# source names the VCN. The "vcn" category covers "existing and future VNICs in
# all subnets in the VCN", so ONE log object replaces AWS's single VPC-level
# flow log with no per-subnet fan-out. Narrower "subnet", "vnic" and "all"
# categories exist if scope needs tightening later.
#
# Off by default, matching every AWS live root and the GCP unit.
###############################################################################

resource "oci_logging_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_log_group_id == null ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-vcn-flow-logs"
  description    = "VCN flow logs for ${var.vcn_display_name}"

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "vcn_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  display_name = "${local.name_prefix}-vcn-flow-log"
  log_group_id = coalesce(var.flow_logs_log_group_id, try(oci_logging_log_group.flow_logs[0].id, null))
  log_type     = "SERVICE"

  configuration {
    compartment_id = var.compartment_id

    source {
      category    = "vcn"
      resource    = oci_core_vcn.this.id
      service     = "flowlogs"
      source_type = "OCISERVICE"
    }
  }

  is_enabled         = true
  retention_duration = var.flow_logs_retention_duration

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}
