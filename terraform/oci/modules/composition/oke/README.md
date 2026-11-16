# composition/oke

OCI Container Engine for Kubernetes. Port of `terraform/aws/modules/composition/eks`.

- Check sheet: `hyperswitch-infra/docs/multi-cloud-parity/oci/modules/eks.md` (verdict **HYBRID**)
- Identity decision it enables: `hyperswitch-infra/docs/multi-cloud-parity/oci/identity-model.md`
- Network model it consumes: `.../oci/network-security-model.md` (Option A, NSGs only)

## What is wrapped, and what is not

`oracle-terraform-modules/oke/oci ~> 5.5` (resolved 5.5.1; verified publisher,
492k downloads, published 2026-08-18) supplies the cluster, node pools, cluster
add-ons, the OKE NSG rule baseline and OKE image resolution.

Switched **off**, because this programme owns them elsewhere:

| Registry feature | Off via | Owned by |
|---|---|---|
| VCN, subnets, gateways, route tables, DRG | `create_vcn = false` + every `vcn_create_* = "never"` + `create_drg = false`; all subnets passed as `{ create = "never", id = <ocid> }` | `composition/vpc-network` |
| Bastion host | `create_bastion = false` | a future `jump-host` module |
| Operator host | `create_operator = false` | no analogue in this stack |
| ArgoCD / Prometheus / Gatekeeper / Cilium / metrics-server / Multus / SR-IOV / RDMA / whereabouts / DCGM / MPI operator | `*_install = false` | `composition/argocd`, `oke-kubernetes-resources`, app units |
| Cluster Autoscaler, Karpenter | `cluster_autoscaler_install = false`, `karpenter_install = false` | **pending oracle gate** — eks.md section 8 item 4 |
| IAM dynamic groups and policies | `create_iam_resources = false` | phase-0 compartment/IAM bootstrap — see `iam.tf` |

Added directly, outside the registry module: `ssh-key.tf` (`tls_private_key` +
`oci_vault_secret`, AWS feature 18 / gap 4.7) and the named-but-unimplemented
cross-account inputs (feature 5 / gap 4.3).

## The three things most likely to surprise you

1. **`cluster_type` is locked to `enhanced`.** OKE Workload Identity — the IRSA
   equivalent all twelve identity-bearing application modules are written
   against — exists on enhanced clusters only. `basic` would remove it with no
   plan-time signal anywhere near the modules that break.
2. **Node pools have no min/max.** `oci_containerengine_node_pool` exposes only
   `size`. `min_size`/`max_size` on `var.node_pools` are advisory metadata
   exported through `node_pool_autoscaler_bounds` for an external autoscaler;
   **nothing at the compute layer enforces them.** An AWS ASG and a GKE node
   pool both would. See eks.md gap 4.5.
3. **One availability domain in `ap-mumbai-1`.** Pools spread across the three
   fault domains inside it (`fault_domains`), not across ADs. The EKS/GKE
   multi-AZ examples do not transfer. Leave `node_pools[*].fault_domains`
   **empty** - it resolves to the live names from
   `data.oci_identity_fault_domains` (`FAULT-DOMAIN-1/2/3` in this tenancy).
   Never write the wrapped registry module's short `FD-N` form: it is that
   module's internal virtual-node-pool placeholder, it is passed through
   untranslated on the managed node-pool path, and OKE rejects it with
   `400-InvalidParameter, Invalid nodeConfigDetails.placementConfigs[].faultDomains`.
   See build-log entry C16.

## Known prerequisite this module cannot satisfy itself

The tenancy's **OKE service policy is missing** (verified 2026-09-03 against the
real `ap-mumbai-1` account). `oci ce cluster-options get` succeeds;
`oci ce node-pool-options get` returns
`RelatedResourceNotAuthorizedOrNotFound: "Unable to retrieve required tenancy
details - please ensure OKE service policy is set up correctly."`

The Terraform data source does not propagate that error — it returns an empty
image set, and the plan fails much later inside the registry module's image
lookup (`setintersection(...): argument must not be null`). Until
`Allow service OKE to manage all-resources in tenancy` exists, node pools must
pin `image_type = "custom"` with an explicit `image_id`. Everything else plans
clean. Details in `iam.tf`.

## Validation

### Additive Per-Pool NSGs

`node_pools[*].nsg_ids` and `node_pools[*].pod_nsg_ids` attach additional
worker and pod NSGs to that pool only. Pod additions require `cni_type = "npn"`.
The dedicated groups can come from the separately managed node-pool security
module; this module owns VNIC membership, not those groups or their rules.

The registry module's managed node pools read `pod_nsg_ids`, not its derived
`pods_nsg_ids` merge. For a nonempty per-pool pod list, this wrapper therefore
explicitly concatenates `module.oke.pod_nsg_id`, `additional_pod_nsg_ids` and
the pool's additions. The output depends on the child network, not its worker
input, so this reference does not introduce a graph cycle. Pools with an empty
list omit the override altogether, preserving upstream defaults. Supplying
`nsg_ids.pods` still means the caller owns that baseline's complete rule set.
NSGs are additive allow-lists, not isolation or deny rules; the OCI VNIC NSG
attachment limit still applies.

The backend-free test uses mock providers and only plans, never applies.
Its assertions check the wrapper inputs; `-verbose` also exposes the real
registry node-pool resource plans for verifying final VNIC membership.
The test syntax requires Terraform 1.9 or newer; the module's existing
Terraform minimum is unchanged.

```
terraform test -filter=tests/pool-nsgs.tftest.hcl -verbose
```

### Static Validation

```
terraform fmt -recursive
terraform init -backend=false
terraform validate
```
