# Internal GCP stack

The GKE cluster, the workloads on it, the two data services those workloads
need, and the edge proxies — for the internal `sandbox`, `dev`, `pre-prod` and `prod`
environments. This stack creates its own VPC.

Rendered by [`terraform/gcp/live/terragrunt.stack.hcl`](../../../live/terragrunt.stack.hcl)
— one `stack` block per environment — into `terraform/gcp/live/<env>/<region>/`.

## Files

| File | Role |
|---|---|
| `terragrunt.stack.hcl` | the 15 `unit` blocks, their `path`s and the `values` each receives |
| `root.hcl` | GCS backend, `google` + `google-beta` providers, and the five locals every unit reads |

`root.hcl` is copied into the generated tree alongside the units, which is how
each unit's `find_in_parent_folders("root.hcl")` resolves.

## Units and phases

| Phase | Units | `path` |
|---|---|---|
| 0. Foundation | `vpc-network` | `vpc-network` |
| 1. Data + cluster | `alloydb`, `memorystore-valkey`, `gke` | `alloydb`, `memorystore-valkey`, `application-stack/gke` |
| 2. Platform apps | `gateway-controller`, `istio`, `argocd`, `external-secrets-operator` | `application-stack/apps/<name>` |
| 3. Workload apps | `loki`, `vector`, `grafana`, `superposition`, `hyperswitch` | `application-stack/apps/<name>` |
| 4. Edge proxies | `envoy-proxy`, `squid-proxy` | `envoy-proxy`, `squid-proxy` |

The edge proxies depend only on `vpc-network`, so Terragrunt will run them
alongside phases 1–3 rather than after — that is fine, nothing in the app tier
depends on them at apply time.

**The dependency graph is complete for this unit set** — every unit that needs
the network or the cluster declares it, so `terragrunt run-all apply` orders
correctly. `gateway-controller` alone has no `dependency` block, and that is
right: it only creates a project-level SSL policy and touches neither the VPC
nor the cluster.

**The `path` values are load-bearing.** Every unit's
`dependency { config_path = "../..." }` is written against this exact layout —
`application-stack/apps/istio` reaches `gke` as `../../gke` and `vpc-network`
as `../../../vpc-network`. Renaming a `path` breaks the graph.

## Values

Consumed by `root.hcl`:

| Value | Required | Default | Notes |
|---|---|---|---|
| `env` | yes | — | one of `sandbox`, `dev`, `pre-prod`, `prod`; anything else is a hard error |
| `region` | yes | — | also the GCS state bucket location |
| `project_id` | yes | — | the GCP project |
| `state_bucket` | yes | — | globally unique; created on first `init` unless `skip_bucket_creation` |
| `project_name` | no | `hyps` | resource-name prefix — see the warning below |
| `vpn_cidr_blocks` | no | `[]` | list of CIDR **strings**; empty means `gke` falls back to an allow-all placeholder |
| `skip_bucket_creation` | no | `false` | set true to point at a bucket managed elsewhere |

Consumed by units:

| Value | Consumed by |
|---|---|
| `vpc_cidr_prefix` | `vpc-network` |
| `gke_pods_secondary_range_cidr`, `gke_services_secondary_range_cidr` | `vpc-network` |
| `machine_types` (`gke_system_pool`, `gke_generic_compute`) | `gke` |
| `domains` (`api`, `grafana`) | `istio`, `grafana`, `hyperswitch` |
| `smtp_secret_id` | `hyperswitch` |
| `custom_images` (`envoy`, `squid`) | `envoy-proxy`, `squid-proxy` — image names, expanded to a full image path against `project_id` |
| `alloydb` (optional map) | `alloydb` — `availability_type`, `cpu_count`, `database_version`, `master_username`, `read_pool_instances`, `deletion_protection` |
| `valkey` (optional map) | `memorystore-valkey` — `shard_count`, `replica_count`, `node_type`, `zone_distribution_config_mode`, `deletion_protection_enabled` |

The `alloydb` and `valkey` maps are passed through conditionally rather than as
`null`: a key present-but-null defeats the unit's own `try(values.X, default)`
fallback, because `try()` rescues evaluation errors, not a resolved null.

### `project_name` is dangerous to change

It defaults to `hyps` rather than `hyperswitch` because GCP service-account IDs
cap at 30 characters and several per-service names overflow that with a longer
prefix. It is the prefix on essentially every resource name the units build,
including the subnet name `memorystore-valkey` looks up.

Pointing this stack at an environment applied under a different prefix without
setting `project_name` to match will rename or recreate that entire
environment on the first apply.

## Prerequisites

- Terragrunt >= 1.1 (CI pins 1.1.1).
- A GCP project with the relevant APIs enabled and credentials in the
  environment. Unlike the AWS side, the GCS state bucket needs no bootstrap
  step: Terragrunt creates it on the first unit's `init`.

## Workflow

```bash
cd terraform/gcp/live
terragrunt stack generate       # renders the unit tree into <env>/<region>/
git add . && git commit         # the generated tree is committed

cd sandbox/asia-south1
terragrunt hcl validate         # resolves every reference — no cloud access needed
terragrunt run-all plan         # needs real credentials and real values
```
