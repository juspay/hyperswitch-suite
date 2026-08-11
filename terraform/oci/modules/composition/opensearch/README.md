# opensearch (OCI) → OCI Search with OpenSearch

OCI equivalent of `terraform/aws/modules/composition/opensearch` (Amazon OpenSearch Service). Uses
`oci_opensearch_opensearch_cluster` (OCI Search with OpenSearch). No verified registry module exists for this
service - raw `oci` provider resource.

## Mapping notes

- AWS combines data/master node config into one `cluster_config` block; OCI separates data, master, and
  dashboard (Kibana-equivalent) node pools as top-level fields.
- AWS `dedicated_master_enabled` → OCI always provisions a distinct master node pool (`master_node_count`); set
  to a low count (e.g. 3) to match AWS's dedicated-master pattern, or omit dedicated masters entirely by pointing
  `master_node_count` at the same size as production needs.
- Fine-grained access control / advanced security options (`advanced_security_options` in AWS) have no direct
  OCI equivalent; OCI OpenSearch clusters are secured via NSGs + IAM policies scoped to the cluster's OCID instead.
