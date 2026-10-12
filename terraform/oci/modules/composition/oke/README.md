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

```
terraform fmt -recursive
terraform init -backend=false
terraform validate
```