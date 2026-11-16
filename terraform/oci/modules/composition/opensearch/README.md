# opensearch (OCI)

**OCI Search with OpenSearch** - a managed-service wrapper, not a VM cluster.
The OCI port of `terraform/aws/modules/composition/opensearch`.

Check sheet: `docs/multi-cloud-parity/oci/modules/opensearch.md`
(hyperswitch-infra).

## Why this module looks nothing like its siblings

The AWS original is **managed**: no `aws_instance`, no `aws_network_interface`,
no EBS volume - it wraps `terraform-aws-modules/opensearch/aws`, which emits one
`aws_opensearch_domain`. So the OCI question was "does OCI have a matching
managed service", and it does. This module contains one
`oci_opensearch_opensearch_cluster`, one NSG, and one optional IAM policy. There
is deliberately **no compute, storage, static-addressing or image-pipeline
scaffolding** here, unlike `../kafka`, `../cassandra` and `../clickhouse`.

The GCP port is a false friend: it runs OpenSearch on Compute Engine because GCP
has no first-party managed equivalent. Copying that here would accept a
regression neither AWS nor OCI requires.

## Provider verification

Every argument was read from `oracle/oci` **9.0.0**'s own JSON schema in-session.
That reading **closed three of the check sheet's open questions - as confirmed
gaps, not as reassurance**:

| Check sheet | Was | Now |
|---|---|---|
| 9.1 storage IOPS/throughput knob | unverified | **absent**. Storage performance follows node shape. `ebs_options.iops`/`.throughput` have nothing to map to. |
| 9.2 customer-managed encryption key | unverified | **absent**. No CMEK argument, no node-to-node TLS toggle. If a customer key is a hard compliance requirement, this is a blocker and needs its own gate item. |
| 9.3 log publishing | unverified | **absent on this resource**. No `log_publishing_options` equivalent - slow-query and audit logs are not reachable from Terraform today. Service Connector Hub as an alternative path remains unexplored. |
| 9.6 one subnet or a list | unverified | **one**. `subnet_id` is a single required string. |

## Divergences that change the input surface

- **`master_node_*` and `opendashboard_node_*` are REQUIRED.** AWS's
  `dedicated_master_enabled = false` has no counterpart; both tiers exist and
  cost money in every environment, dev included.
- **`security_master_user_password_hash` takes a hash, not a plaintext
  password**, and AWS's identity-based `master_user_arn` has no counterpart.
- **Maintenance is a notification channel, not a schedule.** Five AWS variables
  (`auto_tune_*`, `auto_software_update_enabled`, `off_peak_window_*`) are
  dropped. SUBSTITUTE - gate item, not consulted.
- **No service-linked role.** A compartment-level service policy replaces it,
  and **the service-principal name is an inference** that has not been confirmed
  (check sheet 9.4). A wrong name fails the apply cleanly.
- **`availability_domains` is computed, not configurable.** Unlike the
  self-managed modules there is not even a fault-domain lever - placement is
  entirely Oracle's, in a region with one AD.

## Known blockers

- `software_version` has **no default on purpose**: `"OpenSearch_2.13"` is an
  AWS-shaped string and OCI's supported-version list is independent
  (check sheet 9.5, unresolved).
- The service-principal name in `identity.tf` is unverified.

## Validation reached

Rungs 1 and 2 only.
