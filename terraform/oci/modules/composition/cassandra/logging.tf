# =============================================================================
# Per-environment instance log destination (check sheet feature 10, FULL)
# =============================================================================
# Replaces aws_cloudwatch_log_group ("/aws/ec2/cassandra/<env>"). Same primitive
# vpc-network already uses for VCN flow logs.
#
# Two shape differences worth knowing:
#
#   * retention is a per-LOG property on OCI (oci_logging_log.retention_duration),
#     not a log-group property. Valid values are 30-180 days, so an AWS retention
#     outside that range cannot be ported literally. Check sheet open question 9.4.
#   * log_type = "CUSTOM" because these are application logs an agent ships in,
#     not an OCI service's own emissions. As on AWS, creating the destination does
#     NOT make bytes appear in it - a logging agent configured in the custom image
#     does that, equally on both clouds. This is not a new gap introduced by the
#     port, but it is also not observability until the image ships logs.

resource "oci_logging_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-logs"
  description    = "Instance logs for ${local.name_prefix}"

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_logging_log" "this" {
  count = var.enable_logging ? 1 : 0

  log_group_id = oci_logging_log_group.this[0].id
  display_name = local.name_prefix
  log_type     = "CUSTOM"
  is_enabled   = true

  retention_duration = var.log_retention_days

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
