# opensearch-iam

The OpenSearch service-principal IAM policy. Creates exactly one
`oci_identity_policy` that grants the `opensearch` service principal the VCN
permissions it needs to attach a cluster to a customer VCN.

## Why this module exists separately from the composition module's embedded policy

The composition module at `composition/opensearch` has an optional
`oci_identity_policy` (`identity.tf`, gated by `create_service_policy`). That
resource shares the unit's single OCI provider with the cluster. In a
home-region-native deployment (ap-mumbai-1 dev), this works: the provider is
already homed where IAM writes are accepted.

In a non-home-region deployment (us-phoenix-1 prod), it does not. OCI Identity
writes must run under a provider homed in the TENANCY HOME REGION, and the
cluster must run under a REGIONAL provider. One provider cannot be both. The
composition module's policy resource therefore stays disabled
(`create_service_policy = false`) in prod, and this dedicated home-region unit
owns the policy instead.

The split mirrors `oke-cluster-iam` exactly: one tiny module, one policy
object, one unit with a home-region provider override, plan-time fail-open
guards.

## The four documented statements

Oracle's prerequisite documentation for `oci_opensearch_opensearch_cluster`
(docs.oracle.com/en-us/iaas/Content/search-opensearch/Concepts/importingacluster.htm,
verified 2026-11-17) requires FOUR grants, not one aggregate:

```
Allow service opensearch to manage vnics in compartment id <ocid>
Allow service opensearch to use subnets in compartment id <ocid>
Allow service opensearch to use network-security-groups in compartment id <ocid>
Allow service opensearch to manage vcns in compartment id <ocid>
```

A single `use virtual-network-family` aggregate is INSUFFICIENT: the control
plane needs `manage vnics` (it creates cluster-node VNICs) and `manage vcns`,
which a use-level aggregate never grants.

## Guards

- Every statement must name `service opensearch` as the principal. A statement
  that grants to any other principal is rejected at plan time.
- `in compartment <name>` is rejected (server-side lowercasing causes a
  perpetual diff). Only `in compartment id <ocid>` is accepted.
- Max 50 statements per policy object (OCI's hard limit).

## AWS analogue

`aws_iam_service_linked_role` for OpenSearch (`create_service_linked_role`).
OCI has no service-linked-role object; the equivalent is a service POLICY.
