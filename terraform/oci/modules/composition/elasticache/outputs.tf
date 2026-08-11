output "cluster_id" {
  value = oci_redis_redis_cluster.this.id
}

output "primary_endpoint_ip_address" {
  value = oci_redis_redis_cluster.this.primary_endpoint_ip_address
}

output "replicas_endpoint_ip_address" {
  value = oci_redis_redis_cluster.this.replicas_endpoint_ip_address
}
