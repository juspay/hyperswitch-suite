# Output contract. Names follow the OCI concept rather than the AWS one; each
# output's description says which AWS output it answers for. The AWS
# global_replication_group_* / is_*_cluster outputs are NOT emitted - there is
# no corresponding OCI primitive (see the NONE block in main.tf).

output "cluster_id" {
  description = "OCID of the OCI Cache cluster. Answers for both AWS replication_group_id and replication_group_arn - OCI has no separate ARN concept, the OCID is the globally unique identifier."
  value       = oci_redis_redis_cluster.main.id
}

output "display_name" {
  description = "Display name of the cluster, as generated from environment/project_name/name_suffix or overridden."
  value       = oci_redis_redis_cluster.main.display_name
}

output "state" {
  description = "Lifecycle state of the cluster (e.g. ACTIVE). No AWS counterpart output, but it is the field to check before a consumer treats the cache as usable."
  value       = oci_redis_redis_cluster.main.state
}

output "primary_endpoint_ip_address" {
  description = "Private IP of the primary node's endpoint. AWS: replication_group_primary_endpoint_address."
  value       = oci_redis_redis_cluster.main.primary_endpoint_ip_address
}

output "primary_fqdn" {
  description = "Private FQDN of the primary node's endpoint. Prefer this over the IP - TLS is mandatory on OCI Cache and certificate validation needs the hostname."
  value       = oci_redis_redis_cluster.main.primary_fqdn
}

output "replicas_endpoint_ip_address" {
  description = "Private IP of the replica (read) endpoint. AWS: replication_group_reader_endpoint_address."
  value       = oci_redis_redis_cluster.main.replicas_endpoint_ip_address
}

output "replicas_fqdn" {
  description = "Private FQDN of the replica (read) endpoint."
  value       = oci_redis_redis_cluster.main.replicas_fqdn
}

output "discovery_endpoint_ip_address" {
  description = "Private IP of the cluster-topology discovery endpoint. AWS: replication_group_configuration_endpoint_address. NULL on a NONSHARDED cluster - OCI only publishes a discovery endpoint for sharded clusters."
  value       = local.discovery_ip
}

output "discovery_fqdn" {
  description = "Private FQDN of the discovery endpoint. Null on a NONSHARDED cluster."
  value       = local.discovery_fqdn
}

output "port" {
  description = "Port clients connect on. AWS: replication_group_port. Constant 6379 - OCI Cache neither accepts nor exports a port, so this is published as a constant rather than left for each consumer to hardcode."
  value       = local.port
}

output "member_nodes" {
  description = "Display names of every node in the cluster. AWS: replication_group_member_clusters."
  value       = [for n in oci_redis_redis_cluster.main.node_collection[0].items : n.display_name]
}

output "node_collection" {
  description = "Full per-node collection - display name, private endpoint IP and FQDN for each node. Use this when the primary/replica endpoints are not enough (e.g. per-node health checks)."
  value       = oci_redis_redis_cluster.main.node_collection
}

output "subnet_id" {
  description = "Subnet OCID the cluster was placed in. Pass-through of the input. Answers for AWS subnet_group_name/subnet_group_id, neither of which has an OCI counterpart - there is no subnet-group resource."
  value       = oci_redis_redis_cluster.main.subnet_id
}

output "nsg_id" {
  description = "OCID of the module-owned network security group, or null if create_nsg is false. Mirrors the `database` module's nsg_id - THE consumed output: the security-rules equivalent, running last in the stack, writes this cache's ingress rules into it. Added during assembly 2026-09-03."
  value       = var.create_nsg ? oci_core_network_security_group.this[0].id : null
}

output "nsg_ids" {
  description = "Every NSG attached to the cluster - the module-owned one (if created) plus any passed in. Answers for AWS security_group_id/name/arn and all_security_group_ids."
  value       = oci_redis_redis_cluster.main.nsg_ids
}

output "software_version" {
  description = "Engine version actually running. AWS splits this into engine + engine_version_actual."
  value       = oci_redis_redis_cluster.main.software_version
}

output "cluster_mode" {
  description = "SHARDED or NONSHARDED, as applied."
  value       = oci_redis_redis_cluster.main.cluster_mode
}

output "shard_count" {
  description = "Applied shard count. Null/unset on a NONSHARDED cluster. AWS: num_node_groups - note that AWS's live value of 2 is not expressible on OCI (odd, >= 3 only)."
  value       = oci_redis_redis_cluster.main.shard_count
}

output "node_count" {
  description = "Nodes per shard (SHARDED) or total nodes (NONSHARDED), as applied."
  value       = oci_redis_redis_cluster.main.node_count
}

output "node_memory_in_gbs" {
  description = "Memory per node in GB, as applied. The OCI equivalent of AWS's node_type."
  value       = oci_redis_redis_cluster.main.node_memory_in_gbs
}

output "connection_info" {
  description = <<-EOT
    Single object carrying everything a consumer needs to connect. AWS:
    connection_info.

    tls_required is hardcoded true and is NOT a reflection of configuration -
    OCI Cache only accepts TLS connections and offers no way to turn that off
    from Terraform. It is in the contract so a consumer reading this output
    cannot mistake the AWS default (transit_encryption_enabled = false) for
    what happens here.
  EOT
  value = {
    primary_endpoint   = oci_redis_redis_cluster.main.primary_endpoint_ip_address
    primary_fqdn       = oci_redis_redis_cluster.main.primary_fqdn
    reader_endpoint    = oci_redis_redis_cluster.main.replicas_endpoint_ip_address
    reader_fqdn        = oci_redis_redis_cluster.main.replicas_fqdn
    discovery_endpoint = local.discovery_ip
    discovery_fqdn     = local.discovery_fqdn
    port               = local.port
    software_version   = oci_redis_redis_cluster.main.software_version
    cluster_mode       = oci_redis_redis_cluster.main.cluster_mode
    tls_required       = true
  }
}

output "oci_cache_config_set_id" {
  description = "OCID of the config set attached to the cluster, whether module-created or passed in. Null when the cluster runs the service defaults, which is the expected first-cut state. The AWS analogue is parameter_group_name."
  value       = local.config_set_id
}

output "backup_id" {
  description = "OCID of the module-created backup, or null when create_backup is false (the default). One backup, not a schedule - see check sheet feature 10."
  value       = one(oci_redis_oci_cache_backup.main[*].id)
}

output "cache_user_ids" {
  description = "Map of cache user name -> OCID for users this module created and attached. Empty by default. No AWS counterpart output; the AWS module exposes no user identifiers at all."
  value       = { for k, u in oci_redis_oci_cache_user.main : k => u.id }
}

# Deliberately NOT emitted: global_replication_group_id/_arn/_name/_suffix,
# is_primary_cluster, is_secondary_cluster. There is no OCI primitive behind
# them; emitting nulls named after an AWS DR construct would let a consumer
# wire up a passive-region pattern that cannot work here. See the NONE block in
# main.tf.
