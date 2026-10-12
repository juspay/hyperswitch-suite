# Outputs.
# AWS names kept verbatim where the semantics survive; objects with no OCI
# counterpart (ENIs, IAM roles, instance profiles, ARNs) are dropped, not faked.

output "instance_ids" {
  description = "OCIDs of the Cassandra node instances. Replaces instance_ids and instance_arns - OCI has no ARN concept."
  value       = oci_core_instance.cassandra[*].id
}

output "instance_private_ips" {
  description = <<-EOT
    Reserved private IP addresses of the nodes. Replaces instance_private_ips AND
    eni_private_ips, which were distinct on AWS only because the ENI was a
    separate object.

    Sourced from oci_core_private_ip, not from the instance: the instance's own
    primary IP dies with its VNIC, while these survive replacement. This is the
    list a gossip seed configuration must be built from.
  EOT
  value       = local.reserved_ips
}

output "instance_primary_ips" {
  description = "Primary (ephemeral) VNIC IPs. Diagnostic only - do NOT build seed configuration from these."
  value       = oci_core_instance.cassandra[*].private_ip
}

output "reserved_private_ip_ids" {
  description = "OCIDs of the reserved oci_core_private_ip objects. The closest analogue of AWS's eni_ids, and what a node-replacement runbook re-points."
  value       = oci_core_private_ip.node[*].id
}

output "cluster_name" {
  description = "Cassandra cluster name. Unchanged."
  value       = var.cluster_name
}

output "seeds_url" {
  description = <<-EOT
    Seed endpoint. NAME unchanged from AWS; VALUE changes shape by default.

    On AWS this was always an API Gateway invoke URL. Here it is a plain
    comma-separated address list unless enable_seed_discovery = true or an
    external seeds_url was supplied. Any consumer that assumed "this is an HTTP
    endpoint" must be checked before this module replaces the AWS one.
  EOT
  value       = local.seeds_url_value
}

output "native_port" {
  description = "Cassandra native transport port. Unchanged (9042)."
  value       = var.cassandra_ports.native
}

output "subnet_id" {
  description = "Subnet OCID the nodes were placed in. Unchanged in name; the AWS module also had additional_subnet_ids, which has no OCI counterpart (regional subnets, one AD)."
  value       = var.subnet_id
}

output "cassandra_nsg_id" {
  description = "OCID of the module-owned, empty NSG. Replaces cassandra_security_group_id and cassandra_security_group_arn - one value, no ARN. This is the contract composition/security-rules writes rules into."
  value       = try(oci_core_network_security_group.cassandra[0].id, null)
}

output "cassandra_nsg_ids" {
  description = "All NSG OCIDs attached to node VNICs, module-owned plus caller-supplied."
  value       = local.nsg_ids
}

output "key_name" {
  description = "Logical key-pair name. Unchanged in name only - OCI has no key-pair object."
  value       = var.create_key_pair ? local.key_pair_name : var.key_name
}

output "ssh_private_key_vault_secret_id" {
  description = "OCID of the Vault secret holding the generated SSH private key. Replaces ssh_private_key_ssm_parameter. Null when no Vault/KMS key was supplied."
  value       = try(oci_vault_secret.ssh_private_key[0].id, null)
}

# No iam_role_arn / instance_profile output exists: none of those objects exist on
# OCI - the instance-permission binding is a matching rule, not an attachment.
output "dynamic_group_id" {
  description = "OCID of the dynamic group matching this fleet. Partially replaces iam_role_arn / iam_role_name."
  value       = try(oci_identity_dynamic_group.nodes[0].id, null)
}

output "dynamic_group_name" {
  description = "Dynamic group name. Policy statements reference a dynamic group by NAME, not OCID."
  value       = try(oci_identity_dynamic_group.nodes[0].name, null)
}

output "policy_id" {
  description = "OCID of the policy granting the dynamic group its permissions."
  value       = try(oci_identity_policy.nodes[0].id, null)
}

output "log_group_id" {
  description = "OCID of the OCI Logging log group. Replaces the aws_cloudwatch_log_group the AWS module created."
  value       = try(oci_logging_log_group.this[0].id, null)
}

output "log_id" {
  description = "OCID of the custom log."
  value       = try(oci_logging_log.this[0].id, null)
}

output "function_id" {
  description = "OCID of the seed-discovery Function. Replaces seed_discovery_lambda_function_name / _arn. Null unless enable_seed_discovery = true."
  value       = try(oci_functions_function.seed_discovery[0].id, null)
}

output "api_gateway_id" {
  description = "OCID of the seed-discovery API Gateway. Replaces seed_discovery_api_id. Null unless enable_seed_discovery = true."
  value       = try(oci_apigateway_gateway.seed_discovery[0].id, null)
}

output "seed_discovery_invoke_url" {
  description = "Seed-discovery endpoint URL. Replaces seed_discovery_api_invoke_url. Null unless enable_seed_discovery = true."
  value       = local.seed_discovery_url
}

output "availability_domain" {
  description = "Availability domain the ring was placed in. Exactly one exists in ap-mumbai-1."
  value       = local.availability_domain
}

output "fault_domains" {
  description = "Fault domains the ring was spread across - the only in-region fault isolation available."
  value       = local.fault_domains
}
