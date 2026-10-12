# =============================================================================
# Outputs
# =============================================================================
# The output surface is a CONTRACT. Where the semantics survive the port, the
# AWS name is kept verbatim so consuming units do not become translation
# exercises. Where the underlying object does not exist on OCI (ENIs, IAM roles,
# instance profiles) the AWS output is dropped rather than faked - see the
# bottom of this file.

# -----------------------------------------------------------------------------
# Broker tier
# -----------------------------------------------------------------------------
output "broker_instance_ids" {
  description = "OCIDs of the Kafka broker instances. Replaces broker_instance_ids (instance IDs)."
  value       = oci_core_instance.broker[*].id
}

output "broker_private_ips" {
  description = <<-EOT
    Reserved private IP addresses of the brokers. Replaces
    broker_instance_private_ips AND broker_eni_private_ips, which were distinct
    on AWS only because the ENI was a separate object.

    Sourced from oci_core_private_ip, NOT from the instance: the instance's own
    primary IP is ephemeral and dies with its VNIC, while these addresses survive
    instance replacement. This is the list KRaft voter configuration and every
    downstream bootstrap string must be built from.
  EOT
  value       = local.broker_reserved_ips
}

output "broker_instance_primary_ips" {
  description = "Primary (ephemeral) VNIC IPs of the broker instances. Diagnostic only - do NOT build cluster configuration from these; use broker_private_ips."
  value       = oci_core_instance.broker[*].private_ip
}

output "broker_ips_string_list" {
  description = "Comma-separated \"ip:9092\" broker list. Unchanged consumer contract - vector, loki and the hyperswitch drainer read this shape today."
  value       = join(",", [for ip in local.broker_reserved_ips : "${ip}:9092"])
}

# -----------------------------------------------------------------------------
# Controller tier
# -----------------------------------------------------------------------------
output "controller_instance_ids" {
  description = "OCIDs of the KRaft controller instances. A list of controller_count entries; AWS's equivalent was always length 1."
  value       = oci_core_instance.controller[*].id
}

output "controller_private_ips" {
  description = "Reserved private IP addresses of the controllers. Replaces controller_instance_private_ips and controller_eni_private_ips."
  value       = local.controller_reserved_ips
}

output "controller_instance_primary_ips" {
  description = "Primary (ephemeral) VNIC IPs of the controller instances. Diagnostic only."
  value       = oci_core_instance.controller[*].private_ip
}

# -----------------------------------------------------------------------------
# Reserved private IP objects - the static-address mechanism itself
# -----------------------------------------------------------------------------
output "broker_reserved_private_ip_ids" {
  description = "OCIDs of the brokers' reserved oci_core_private_ip objects. The closest thing this port has to AWS's broker_eni_ids, and what a replacement runbook re-points."
  value       = oci_core_private_ip.broker[*].id
}

output "controller_reserved_private_ip_ids" {
  description = "OCIDs of the controllers' reserved oci_core_private_ip objects. Replaces controller_eni_ids."
  value       = oci_core_private_ip.controller[*].id
}

# -----------------------------------------------------------------------------
# Network security - consumed by composition/security-rules
# -----------------------------------------------------------------------------
output "broker_nsg_id" {
  description = "OCID of the module-owned, empty broker NSG. Replaces broker_security_group_id and is the contract the security-last phase writes rules into."
  value       = try(oci_core_network_security_group.broker[0].id, null)
}

output "controller_nsg_id" {
  description = "OCID of the module-owned, empty controller NSG. Replaces controller_security_group_id."
  value       = try(oci_core_network_security_group.controller[0].id, null)
}

output "broker_nsg_ids" {
  description = "All NSG OCIDs attached to broker VNICs, module-owned plus caller-supplied."
  value       = local.broker_nsg_ids
}

output "controller_nsg_ids" {
  description = "All NSG OCIDs attached to controller VNICs, module-owned plus caller-supplied."
  value       = local.controller_nsg_ids
}

# -----------------------------------------------------------------------------
# SSH
# -----------------------------------------------------------------------------
output "key_name" {
  description = "Logical key-pair name. Unchanged from AWS in name only - OCI has no key-pair object, so nothing on the cloud side carries this string."
  value       = var.create_key_pair ? local.key_pair_name : var.key_name
}

output "ssh_private_key_vault_secret_id" {
  description = "OCID of the Vault secret holding the generated SSH private key. Replaces ssh_private_key_ssm_parameter. Null when no Vault/KMS key was supplied - in which case the key exists only in Terraform state."
  value       = try(oci_vault_secret.ssh_private_key[0].id, null)
}

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------
# There is no instance_profile_name output and no iam_role_arn output, because
# neither object exists on OCI. Nothing replaces them 1:1: the binding between
# instance and permissions is the dynamic group's matching rule, not an
# attachment, so the pair below is the whole identity surface.
output "dynamic_group_id" {
  description = "OCID of the dynamic group matching this fleet's instances. Partially replaces iam_role_arn / iam_role_name."
  value       = try(oci_identity_dynamic_group.nodes[0].id, null)
}

output "dynamic_group_name" {
  description = "Name of the dynamic group. Policy statements reference a dynamic group by NAME, not OCID, which is why this is exported."
  value       = try(oci_identity_dynamic_group.nodes[0].name, null)
}

output "policy_id" {
  description = "OCID of the policy granting the dynamic group its permissions. No AWS counterpart - the AWS side had a role and inline policies instead."
  value       = try(oci_identity_policy.nodes[0].id, null)
}

# -----------------------------------------------------------------------------
# Placement, for the security-rules and monitoring units
# -----------------------------------------------------------------------------
output "availability_domain" {
  description = "Availability domain every node was placed in. Exactly one exists in ap-mumbai-1."
  value       = local.availability_domain
}

output "fault_domains" {
  description = "Fault domains the fleet was spread across. The only in-region fault isolation available - see compute.tf."
  value       = local.fault_domains
}
