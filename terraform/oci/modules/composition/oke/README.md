# composition/oke

OCI Container Engine for Kubernetes (OKE) cluster via the
`oracle-terraform-modules/oke/oci` registry module (`~> 5.5`). Creates the
cluster, node pools, node-pool placement, an SSH keypair stored in OCI Vault,
and disables registry-owned networking features the stack provisions elsewhere
(see `vpc-network`).

## Usage notes

- **`cluster_type` is fixed to `enhanced`.** OKE Workload Identity is only
  available on enhanced clusters; `basic` silently removes it.
- **Node pools expose only `size`.** `min_size`/`max_size` are advisory
  metadata exported as `node_pool_autoscaler_bounds` for an external
  autoscaler; nothing at the compute layer enforces them.
- **`ap-mumbai-1` has one availability domain.** Node pools spread across the
  three fault domains within that AD, not across ADs. Leave `fault_domains`
  empty to resolve from `data.oci_identity_fault_domains`; never use the
  registry module's short `FD-N` form, which is rejected by OKE on the managed
  node-pool path.

## Prerequisite

The tenancy must have an OKE service policy (`Allow service OKE to manage
all-resources in tenancy`). Without it, node-pool image resolution fails
(`RelatedResourceNotAuthorizedOrNotFound`) and node pools must pin
`image_type = "custom"` with an explicit `image_id`.

## Validation

### Additive Per-Pool NSGs

`node_pools[*].nsg_ids` and `node_pools[*].pod_nsg_ids` add worker and pod
NSGs to one pool. Pod additions require `cni_type = "npn"`. Groups can come
from `composition/node-pool-security`; their rules remain separately owned.

The registry module's managed pools read `pod_nsg_ids`, not its derived
`pods_nsg_ids` merge. For a nonempty per-pool list, this wrapper explicitly
combines `module.oke.pod_nsg_id`, `additional_pod_nsg_ids`, and pool additions.
That output depends on child networking, not worker inputs, so the reference
does not create a graph cycle. Empty lists omit the override and preserve
upstream defaults. Supplying `nsg_ids.pods` means the caller owns the baseline
rules. NSGs are additive allow-lists, not deny rules; VNIC attachment limits
still apply. No isolation is enabled by default.

`terraform test -filter=tests/pool-nsgs.tftest.hcl` uses mock providers and
requires Terraform >= 1.9. It checks the wrapper inputs; add `-verbose` to
inspect final managed and autoscaled node-pool VNIC attachments in the real
registry resource plans without credentials or cloud operations.

### Static Validation

```
terraform fmt -recursive
terraform init -backend=false
terraform validate
```
