output "cluster_id" {
  value = oci_opensearch_opensearch_cluster.this.id
}

output "opensearch_fqdn" {
  value = oci_opensearch_opensearch_cluster.this.opensearch_fqdn
}

output "opendashboard_fqdn" {
  value = oci_opensearch_opensearch_cluster.this.opendashboard_fqdn
}

output "opensearch_private_ip" {
  value = oci_opensearch_opensearch_cluster.this.opensearch_private_ip
}
