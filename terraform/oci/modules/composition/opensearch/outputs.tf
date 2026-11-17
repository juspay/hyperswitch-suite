# =============================================================================
# Outputs
# =============================================================================
# AWS names kept where the semantics survive. Where the object does not exist on
# OCI (ARNs, service-linked roles, CloudWatch log groups) the output is dropped
# rather than faked - see the notes at the bottom.

output "cluster_id" {
  description = "OCID of the OpenSearch cluster. Replaces domain_id and domain_arn - OCI has no ARN concept."
  value       = oci_opensearch_opensearch_cluster.this.id
}

output "cluster_name" {
  description = "Cluster display name. Replaces domain_name."
  value       = oci_opensearch_opensearch_cluster.this.display_name
}

output "opensearch_fqdn" {
  description = "FQDN of the OpenSearch API endpoint. Replaces domain_endpoint / domain_endpoint_v2, which were two names for one thing on AWS."
  value       = oci_opensearch_opensearch_cluster.this.opensearch_fqdn
}

output "opensearch_private_ip" {
  description = "Private IP of the OpenSearch API endpoint. No AWS counterpart - an Amazon domain exposes only a hostname."
  value       = oci_opensearch_opensearch_cluster.this.opensearch_private_ip
}

output "opendashboard_fqdn" {
  description = "FQDN of the OpenSearch Dashboards endpoint. Replaces dashboard_endpoint / dashboard_endpoint_v2."
  value       = oci_opensearch_opensearch_cluster.this.opendashboard_fqdn
}

output "opendashboard_private_ip" {
  description = "Private IP of the Dashboards endpoint. No AWS counterpart."
  value       = oci_opensearch_opensearch_cluster.this.opendashboard_private_ip
}

output "kibana_url" {
  description = "Dashboards UI URL. Replaces kibana_url and kibana_url_legacy - the \"legacy\" variant existed only because Amazon renamed Kibana to Dashboards mid-life."
  value       = local.kibana_url
}

output "nsg_id" {
  description = "OCID of the NSG gating data-plane access. Replaces security_group_id, security_group_arn and all_security_group_ids - one value, no ARN, no list, because the cluster resource accepts exactly one NSG."
  value       = local.nsg_id
}

output "total_storage_gb" {
  description = "Total provisioned cluster storage, GB. No AWS equivalent output; useful for capacity dashboards."
  value       = oci_opensearch_opensearch_cluster.this.total_storage_gb
}

output "availability_domains" {
  description = <<-EOT
    Availability domains Oracle placed the cluster's nodes across. COMPUTED, not
    configured - there is no input counterpart to AWS's zone_awareness_enabled /
    availability_zone_count, and ap-mumbai-1 has exactly one AD. Exported so the
    value is visible rather than assumed.
  EOT
  value       = oci_opensearch_opensearch_cluster.this.availability_domains
}

output "service_policy_id" {
  description = <<-EOT
    OCID of the service policy authorizing the OpenSearch control plane to attach
    to the customer VCN. Null when create_service_policy = false.

    The nearest thing to AWS's service_linked_role_arn / _name, but NOT a
    replacement for them: a policy is a different object from a role, and the
    AWS outputs are dropped rather than renamed onto this one.
  EOT
  value       = try(oci_identity_policy.service[0].id, null)
}

output "connection_info" {
  description = "Connection summary, same role as the AWS output of the same name."
  value = {
    cluster_id        = oci_opensearch_opensearch_cluster.this.id
    opensearch_fqdn   = oci_opensearch_opensearch_cluster.this.opensearch_fqdn
    opensearch_ip     = oci_opensearch_opensearch_cluster.this.opensearch_private_ip
    dashboards_fqdn   = oci_opensearch_opensearch_cluster.this.opendashboard_fqdn
    dashboards_ip     = oci_opensearch_opensearch_cluster.this.opendashboard_private_ip
    software_version  = var.software_version
    data_node_count   = var.data_node_count
    master_node_count = var.master_node_count
    security_mode     = var.security_mode
    nsg_id            = local.nsg_id
    total_storage_gb  = oci_opensearch_opensearch_cluster.this.total_storage_gb
    lifecycle_details = oci_opensearch_opensearch_cluster.this.lifecycle_details
  }
}

output "subnet_id" {
  description = "Subnet OCID the cluster attached to. Replaces subnet_ids (a list on AWS; the OCI resource takes exactly one)."
  value       = var.subnet_id
}

output "vcn_id" {
  description = "VCN OCID the cluster attached to. Replaces vpc_id."
  value       = var.vcn_id
}

# DROPPED, deliberately, with no substitute:
#
#   cloudwatch_log_groups - the cluster resource has NO log_publishing_options
#     equivalent (confirmed absent from the 9.0.0 schema, not merely unverified),
#     so there is no per-log-type destination to export. Slow-query and audit
#     logging are not reachable from Terraform on this service today.
#     Check sheet feature 9, PARTIAL, section 4.5.
#
#   service_linked_role_arn / service_linked_role_name - no such object on OCI;
#     see service_policy_id above and identity.tf.
