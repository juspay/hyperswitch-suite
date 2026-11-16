# composition/oke-kubernetes-resources

OCI equivalent of `terraform/aws/modules/composition/eks-kubernetes-resources`
- **current cut narrowly implements ONLY the AWS `cluster_access_entries`
  parity feature** (eks.md gap 4.2, verdict **SUBSTITUTE**). Storage classes,
  default/custom RBAC `ClusterRole`s, the cluster-autoscaler and the
  hyperswitch helm release are separate, independently gated features not yet
  ported here.

- Check sheet: `hyperswitch-infra/docs/multi-cloud-parity/oci/modules/eks-kubernetes-resources.md`
- Oracle gate verdict: **APPROVED WITH CORRECTIONS** (eks.md §8 item 2) -
  the design was consulted on 2026-09-08, deferred from CI-side conditioned
  authoring to a manually-applied in-session implementation per the user's
  directive.

## Why it exists

On AWS, `eks-01`'s `cluster_access_entries` maps a list of IAM principal
ARNs to managed EKS access policies (`AmazonEKSClusterAdminPolicy` etc.). On
OCI there is **no managed policy bundle** - OKE authenticates IAM
principals by OCID through the OKE exec credential, and native Kubernetes
`ClusterRoleBinding`s/`RoleBinding`s decide what a principal may do inside
the cluster. This module is the RBAC half of that pair.

The IAM half - "may this principal call `oci ce cluster generate-token`" -
is an `oci_identity_policy` (`Allow group <name> to use clusters in compartment
<compartment>`) and lives in the **phase-0 IAM bootstrap**, exactly as
`oci/oke/iam.tf` feature 4 dictates. This module is deliberately NOT wrapped
up with that half.

`oke` (phase 1) is the cluster, this is phase 2 - and the `kubernetes`
provider needs a live endpoint + CA to plan, so this is a separate state/unit
gated on `terraform_data.cluster_ready`.

## What it does not do yet

| Feature of the AWS parent                                                                 | Status here             |
|---|---|
| `cluster_access_entries`                                                                  | **ported** (this module) |
| `create_default_rbac_roles` / `custom_rbac_roles`                                         | deliberately not ported - oracle gate said "do not add", and eks-kubernetes-resources.md §9 flags them as possibly redundant alongside per-principal bindings |
| default / custom `kubernetes_storage_class_v1`                                             | not ported              |
| Cluster Autoscaler (OCI cloudprovider) as an in-cluster add-on             | **ported** - `autoscaler.tf` (aws's `kubernetes_deployment_v1` re-flagged `--cloud-provider=oci` + static `--nodes=` rendered from the oke module's `node_pool_autoscaler_bounds`). Oracle gate eks.md §8 item 4 APPROVED WITH CORRECTIONS, 2026-09-08. Requires the phase-0 IAM bootstrap (worker dynamic group + 6 policies) and an OCIR mirror copy at apply. |
| `hyperswitch` helm release + registry pull secret                                          | not ported              |

## How the kubernetes provider authenticates

AWS used a static token: `data.aws_eks_cluster_auth.cluster.token`. OKE has
**no static-token data source**. This module's provider is configured with
the `exec` plugin - the same mechanism `oci ce cluster create-kubeconfig`
writes into `~/.kube/config`, captured verbatim:

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

The exec stanza's args were captured from the live dev cluster's kubeconfig
(`oci ce cluster create-kubeconfig` output), not asserted from memory.

### Runner prerequisites

- `oci` CLI installed (matches `oci/oke`'s own requirement for
  terraform-driven applies).
- The caller's principal must itself have `use clusters` IAM permission
  (`identity-model.md`'s `GenerateClusterKubeconfig` operation) - this is the
  IAM half, owned by the phase-0 bootstrap.
- A binding WITHOUT that IAM statement produces a kubeconfig that 401s on the
  very first API call: a config, not access.

## Inputs

- `cluster_id`, `cluster_endpoint`, `cluster_ca_cert` - from `oci/oke`'s
  `cluster_id` / `cluster_endpoint` / `cluster_ca_cert` outputs.
- `region` - from the environment's `root.hcl` locals.
- `cluster_access_bindings` - map of name -> {scope_kind, namespace?, role_ref, subjects}.
  - `scope_kind`: `"cluster"` (ClusterRoleBinding) or `"namespace"` (RoleBinding).
  - `role_ref`: built-in (`cluster-admin`, `view`, `edit`) or custom; `kind`
    must match scope_kind (`{kind = ClusterRole, name = ...}` for the usual
    case, `{kind = Role, ...}` only with scope_kind = "namespace").
  - `subjects`: list of `{kind = User|Group, name = OCID}`. The kind prefix
    MUST match the OCID (`ocid1.user.oc1..` / `ocid1.group.oc1..`) - a
    mismatch silently grants nothing. This is enforced by variable
    validation (the Oracle gate's #2 correction).
- `labels`, `annotations` - optional.

## Validation / outputs

`terraform validate` clean, plus these verified plan-time guards:

- OCID-kind mismatch (Group kind + user OCID) **blocked** at plan time.
- scope_kind / namespace mismatch **blocked** at plan time.
- `cluster_access_bindings = {}` produces a clean no-op (only the
  `terraform_data.cluster_ready` placeholder) - the Oracle gate's #3.

Outputs: `cluster_access_bindings` (what was actually created).

## Validation ladder

- rung 1: `terraform validate` **passed** (in-session).
- rung 2: `terraform fmt -check` **passed**.
- rung 3: `terragrunt stack generate` on the OCI dev stack produces
  `oke-kubernetes-resources/` - see the `hyperswitch-infra` catalog unit.
- rung 4: plan covered with a mock+real-binding set (three entries mirroring
  eks-01's `admin_sso_role`, `view_sso_role`, `reliability_scorecard_workflow`).
- rung 5: **passed 2026-09-08 against the real live cluster** (`terragrunt
  plan` on the dev `oke-kubernetes-resources` unit resolves real outputs from
  the `oke` unit's state - real cluster_id / endpoint / CA - and produces a
  clean plan). This verified a UX bug found only at this rung: an
  oke-kubernetes-resources binding entry whose `subjects` list is empty (e.g.
  stack values that leave `admin_session_group_ocid`/`view_session_group_ocid`
  unset) previously emitted a ClusterRoleBinding/RoleBinding with zero
  subjects, which Kubernetes rejects with `Insufficient subject blocks`. The
fix (both CRB and RB `for_each` filters to `length(subjects) > 0`) means an
   unset group OCID now degrades to a clean no-op instead of a plan error;
   the real bindings materialize once the OCIDs are supplied in
   `terragrunt.values.hcl`.
- rung 6 (Cluster Autoscaler, added 2026-09-08): `terraform validate`/`fmt`
  clean with the autoscaler in place. A scratch plan with
  `enable_cluster_autoscaler = true`, the OCIR image supplied, and both dev
  pools' bounds produces **exactly 7 resources** (SA, ClusterRole,
  ClusterRoleBinding, Role, RoleBinding, Deployment, + `cluster_ready`), with
  `--nodes` args `1:10:<ocid>` (generic-compute) and `2:5:<ocid>`
  (system-pool) rendered sorted and correctly. The guard trap is a **hard
  plan-time failure**: `enable_cluster_autoscaler = true` without either the
  image or a non-empty node-pools map aborts the plan via a precondition on
  `cluster_ready` (not a soft check-block warning). Live `terragrunt plan` on
  the dev unit (autoscaler off by default) stays a clean `1 to add` no-op.
  The autoscaler's apply-time IAM + image prereqs (worker dynamic group + 6
  policies; OCIR mirror copy) are documented prereqs, not auto-created.
