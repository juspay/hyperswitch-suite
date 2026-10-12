# composition/oke-kubernetes-resources

Terraform `kubernetes`-provider resources for an OKE cluster: `ClusterRole` /
`Role` bindings from a `cluster_access_bindings` map, plus an optional
in-cluster cluster-autoscaler deployment. Runs in phase 2, after the `oke`
cluster exists (the `kubernetes` provider needs a live endpoint + CA).

## How the provider authenticates

OKE has no static-token data source. The provider uses the OCI `exec`
plugin — the same mechanism `oci ce cluster create-kubeconfig` writes into
`~/.kube/config`:

```hcl
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args = [
      "ce", "cluster", "generate-token",
      "--cluster-id", var.cluster_id,
      "--region", var.region,
    ]
  }
}
```

### Runner prerequisites

- `oci` CLI installed.
- The principal must have `use clusters` IAM permission (managed by the phase-0
  OKE identity bootstrap). Without it the generated kubeconfig 401s on the
  first API call.

## Inputs

- `cluster_id`, `cluster_endpoint`, `cluster_ca_cert` — from the `oke` module's
  outputs.
- `region` — from the environment's root locals.
- `cluster_access_bindings` — map of name -> `{scope_kind, namespace?, role_ref, subjects}`.
  - `scope_kind`: `"cluster"` (ClusterRoleBinding) or `"namespace"` (RoleBinding).
  - `role_ref`: built-in (`cluster-admin`, `view`, `edit`) or custom; `kind`
    must match scope_kind.
  - `subjects`: list of `{kind = User|Group, name = OCID}`. The `kind` prefix
    **must** match the OCID (`ocid1.user.oc1..` / `ocid1.group.oc1..`) — a
    mismatch silently grants nothing.
- `labels`, `annotations` — optional.

## Guards (plan time)

- OCID-kind mismatch is blocked.
- `scope_kind` / `namespace` mismatch is blocked.
- An empty `cluster_access_bindings = {}` is a clean no-op.

## Validation

`terraform validate` and `terraform fmt -check` are clean. Live `terragrunt
plan` against the dev cluster resolves real output values from the `oke` unit's
state.