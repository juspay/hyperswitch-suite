###############################################################################
# Output contract
#
# Deliberately ABSENT, each a recorded gap rather than a silent drop:
#
#   - iam_role_arn / instance_profile_name: OCI has no per-instance role
#     object. SUBSTITUTE, owned by oci/identity-model.md, not by this module.
#   - ssm_document_name / session_preferences_*: aws_ssm_document has no OCI
#     counterpart at all (check sheet feature 5, PARTIAL). What survives -
#     session TTL and the run-as OS user - lives on the bastion and session
#     resources, not on a separate preferences document, so there is no
#     document id to export.
#   - ssm_session_log_group_name / ssm_session_log_bucket for SESSION CONTENT:
#     no managed session-content logging exists (features 3 and 4, verdict
#     NONE). session_log_bucket_name below is a destination for a SELF-MANAGED
#     recorder that this module does not create and the platform does not yet
#     run. Do not read its existence as parity.
###############################################################################

output "jump_instance_id" {
  description = "OCID of the jump instance."
  value       = oci_core_instance.this.id
}

output "jump_instance_name" {
  description = "Display name of the jump instance."
  value       = oci_core_instance.this.display_name
}

output "jump_private_ip" {
  description = "Private IP of the jump instance - the address a Bastion PORT_FORWARDING session targets."
  value       = oci_core_instance.this.private_ip
}

output "bastion_id" {
  description = "OCID of the OCI Bastion. NEW output with no AWS counterpart: SSM needs no per-account broker object, so there was nothing to export. Needed to construct every session-creation command."
  value       = local.bastion_id
}

output "bastion_private_endpoint_ip" {
  description = <<-EOT
    Private endpoint IP of the OCI Bastion.

    THE SINGLE MOST LOAD-BEARING OUTPUT ON THIS MODULE. It is the source
    address of the one inbound rule that OCI Bastion requires and that AWS's
    zero-ingress security group never needed. catalog/units/oci/security-rules
    must write:

        ingress, TCP 22, source = <this value>/32

    into this module's nsg_id. Without it every session type fails, and with a
    connectivity error rather than an exposure - NSG rules are allow-only, so
    the failure direction is safe but the debug cycle is wasted.

    Check sheet §3 item 8 / §4 "#8 - Security group".
  EOT
  value       = local.bastion_private_endpoint_ip
}

output "nsg_id" {
  description = "OCID of the module-owned NSG on the jump instance's VNIC. Replaces AWS's security_group_id. Created empty; security-rules fills it - and unlike the AWS original it cannot stay empty, see bastion_private_endpoint_ip."
  value       = try(oci_core_network_security_group.this[0].id, null)
}

output "log_group_id" {
  description = "OCID of the host log group. Replaces AWS's cloudwatch_log_group_name. There is no second log group for session content because there is no session content to log."
  value       = oci_logging_log_group.this.id
}

output "log_id" {
  description = "OCID of the host custom log inside the log group. OCI splits container and stream across two resources where CloudWatch has one."
  value       = oci_logging_log.host.id
}

output "session_log_bucket_name" {
  description = "Name of the SELF-MANAGED session-recording bucket, or null when enable_session_recording is false. A destination only - no OCI service writes session content to it, and this module creates no recorder. Features 3 and 4 are NONE."
  value       = try(oci_objectstorage_bucket.session_logs[0].name, null)
}

output "object_storage_namespace" {
  description = "Object Storage namespace. No AWS counterpart; needed to address the bucket."
  value       = local.namespace
}

output "connection_targets" {
  description = "Echo of the endpoints this host is meant to be tunnelled through to, as wired at the live/unit layer. Informational."
  value       = var.connection_targets
}

output "connection_guide" {
  description = "Rendered operator guide. Same output SHAPE as the AWS module's; the content is rewritten for `oci bastion session create-port-forwarding` and carries the SSH-keypair step AWS's guide never needed."
  value       = local.connection_guide
}

output "migration_mode_status" {
  description = "Whether migration mode was CONFIGURED on - recomputed from the variable, not derived from a resource, because OCI Run Command has no Terraform resource in oracle/oci 9.0.0. It therefore cannot tell you whether the grant is live, only what this configuration asked for. PARTIAL, check sheet feature 10."
  value       = local.migration_mode_status
}

output "availability_domain" {
  description = "Availability domain the instance was created in. Exported because it is resolved from a data source, not supplied."
  value       = local.availability_domain
}
