# Internal GCP stack

Full single-region composition of the GCP catalog for internal `sandbox`,
`dev`, `pre-prod` and `prod` environments. This stack creates its own VPC and
wires every catalog unit.

Rendered by [`terraform/gcp/live/terragrunt.stack.hcl`](../../../live/terragrunt.stack.hcl)
— one `stack` block per environment — into `terraform/gcp/live/<env>/<region>/`.

## Files

| File | Role |
|---|---|
| `terragrunt.stack.hcl` | the 34 `unit` blocks, their `path`s and the `values` each receives |
| `root.hcl` | GCS backend, `google` + `google-beta` providers, and the five locals every unit reads |

`root.hcl` is copied into the generated tree alongside the units, which is how
each unit's `find_in_parent_folders("root.hcl")` resolves.

## Units and phases

| Phase | Units | `path` |
|---|---|---|
| 0. Foundation | `vpc-network` | `vpc-network` |
| 1. Data + compute | `cloud-sql`, `memorystore`, `artifact-registry`, `filestore`, `pubsub`, `cloud-dns`, `certificate-manager`, `bastion-host`, `kafka`, `cassandra`, `clickhouse`, `opensearch`, `locker`, `gke` | same |
| 2. Cluster resources | `gke-kubernetes-resources` | same |
| 3. Platform apps | `gateway-controller`, `istio`, `argocd`, `external-secrets-operator`, `otel-collector` | `apps/<name>` |
| 4. Workload apps | `loki`, `vector`, `grafana`, `superposition`, `decision-engine`, `ratelimiter`, `hyperswitch` | `apps/<name>` |
| 5. Edge | `load-balancer`, `cloud-cdn`, `envoy-proxy`, `squid-proxy`, `cloud-monitoring` | same |
| 6. Firewall rules | `firewall-rules` (apply last) | `firewall-rules` |

34 units total. The phases are banner comments only.

**Terragrunt will not enforce this order.** Every `dependency` block in the
catalog points at either `vpc-network` or `gke` — the graph is two levels deep,
so a single `run-all apply` schedules almost everything concurrently once those
two exist. Six units besides `vpc-network` have no `dependency` block at all —
`apps/gateway-controller`, `artifact-registry`, `certificate-manager`,
`cloud-cdn`, `cloud-monitoring` and `pubsub` — including
`apps/gateway-controller`, which genuinely needs the cluster, and
`certificate-manager`, whose own comment says it reads DNS authorization
records from `cloud-dns`.

`firewall-rules` is likewise marked "apply last" but depends only on
`vpc-network`, so nothing stops it running early.

Until the missing `dependency` blocks are added, apply phase by phase by hand —
see [`live/README.md`](../../../live/README.md#deployment-order).

**The `path` values are load-bearing.** Every unit's
`dependency { config_path = "../..." }` (e.g. `apps/istio`'s
`config_path = "../../gke"`) is written against this exact layout. Renaming a
unit's `path` here without updating every `config_path` that points at it
breaks the dependency graph.

Two units provision their own dependencies rather than reading a shared one:
`locker` creates a dedicated Cloud SQL instance, and `apps/ratelimiter` creates
a dedicated Memorystore instance. Neither needs `cloud-sql` / `memorystore`
applied first unless that behaviour is turned off in the unit.

## VPC mode

No unit in this stack is passed a pre-existing network. Every VPC-consuming
unit reads its networking inputs from the `vpc-network` unit created here.
There is no BYO-VPC stack for GCP yet — the AWS `stacks/standalone` equivalent
would be the starting point if self-hosting on GCP becomes a goal.

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
| `vpc_cidr_prefix` | `vpc-network` and 12 others |
| `gke_pods_secondary_range_cidr` | `vpc-network`, `apps/ratelimiter` |
| `gke_services_secondary_range_cidr` | `vpc-network` |
| `domains` (`api`, `grafana`) | `certificate-manager`, `apps/istio`, `apps/grafana`, `apps/hyperswitch`, `envoy-proxy` |
| `custom_images` (9 keys) | `kafka`, `cassandra`, `clickhouse`, `opensearch`, `locker`, `envoy-proxy`, `squid-proxy` |
| `machine_types` (3 keys) | `gke`, `bastion-host` |
| `bastion_iap_members` | `bastion-host` |
| `alert_notification_email` | `cloud-monitoring` |
| `smtp_secret_id` | `apps/hyperswitch`, `apps/decision-engine` |

### `project_name` is dangerous to change

It defaults to `hyps` rather than `hyperswitch` because GCP service-account IDs
cap at 30 characters and several per-service names overflow that with a longer
prefix. It is the prefix on essentially every resource name the units build.

Pointing this stack at an environment that was applied under a different prefix
without setting `project_name` to match will rename or recreate that entire
environment on the first apply.

## Prerequisites

- Terragrunt >= 1.1 (CI pins 1.1.1).
- All 34 module tags cut — see the table in [`../../README.md`](../../README.md).
- A GCP project with the relevant APIs enabled and credentials in the
  environment. Unlike the AWS side, the GCS state bucket needs no bootstrap
  step: Terragrunt creates it on the first unit's `init`.

## Workflow

```bash
cd terraform/gcp/live
terragrunt stack generate       # renders the unit tree into <env>/<region>/
git add . && git commit         # the generated tree is committed

cd sandbox/asia-south1
terragrunt hcl validate         # resolves every reference — cheap, no cloud access
terragrunt run-all plan         # needs real credentials and real values
```
