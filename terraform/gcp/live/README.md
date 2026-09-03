# GCP live layer

Internal GCP environments, generated from
[`terraform/gcp/catalog/stacks/internal`](../catalog/stacks/internal/README.md)
by [`terragrunt.stack.hcl`](./terragrunt.stack.hcl).

There is no hand-maintained Terraform here. `terragrunt.stack.hcl` is the only
file to edit; everything under `sandbox/` (and any environment added later) is
generated and then committed.

## Regenerating

```bash
cd terraform/gcp/live
terragrunt stack generate
git status   # review the diff before committing
```

Run this after changing `terragrunt.stack.hcl` or any unit under
`catalog/units/`. CI fails if the committed tree differs from a fresh generate.

`terragrunt stack generate` only renders files — it does not evaluate unit
inputs, so a clean generate does not mean `plan` will succeed. The cheap next
check is:

```bash
cd terraform/gcp/live/sandbox/asia-south1
terragrunt hcl validate     # resolves every local, values and dependency reference
```

That needs no cloud credentials and no module downloads, and it catches the
whole class of "unit reads a `values` key the stack does not pass" errors.

## Before anything can run

1. **Module tags must exist.** 24 of the 34 modules this catalog pins are still
   only on the `feat/gcp-terraform-modules` branch. `terragrunt init` fails with
   a remote-ref error until they are merged and tagged — run
   `scripts/ci/check-gcp-pins.sh` for the exact list.
2. **Replace every `REPLACE_ME`.** Search this directory and
   `terragrunt.stack.hcl` for them.

| Placeholder | What it needs |
|---|---|
| `project_id` | the real GCP project |
| `state_bucket` | a globally unique GCS bucket name; Terragrunt creates it on first `init` |
| `vpn_cidr_blocks` | real office / VPN CIDRs. **Left empty, `gke` falls back to an allow-all `master_authorized_networks` entry that must not be applied.** |
| `domains.api`, `domains.grafana` | real hostnames |
| `custom_images.*` | 9 pre-baked GCE images. `terraform/gcp/packer/` covers envoy and squid only — the other 7 have no image-build pipeline yet |
| `bastion_iap_members` | the group(s) or user(s) granted IAP SSH |
| `alert_notification_email` | a real on-call channel |

## Deployment order

Terragrunt derives run order from `dependency` blocks, and this catalog's graph
is only two levels deep — every dependency points at `vpc-network` or `gke`.
**A single `terragrunt run-all apply` will not respect the phases below.** Until
the missing `dependency` blocks are added, apply phase by phase.

```bash
cd terraform/gcp/live/sandbox/asia-south1
```

**Phase 0 — foundation.** Everything else needs the network. This is also the
apply that creates the GCS state bucket.

```bash
terragrunt apply --working-dir vpc-network
```

**Phase 1 — data layer and cluster.** These are mutually independent and can run
concurrently, but `gke` is the long pole (~15–20 min) so start it first.

```bash
terragrunt apply --working-dir gke
# then, in any order / in parallel:
#   cloud-sql  memorystore  artifact-registry  filestore  pubsub  cloud-dns
#   certificate-manager  bastion-host  kafka  cassandra  clickhouse
#   opensearch  locker
```

`locker` provisions its own Cloud SQL instance and `apps/ratelimiter` its own
Memorystore instance, so neither waits on `cloud-sql` / `memorystore`.
`certificate-manager` reads DNS authorization records from `cloud-dns` — apply
`cloud-dns` first even though no `dependency` block enforces it.

**Phase 2 — cluster resources.** Must land before any app.

```bash
terragrunt apply --working-dir gke-kubernetes-resources
```

**Phase 3 — platform apps.** `gateway-controller` and `istio` provide the
ingress every workload app attaches to.

```bash
#   apps/gateway-controller  apps/istio  apps/argocd
#   apps/external-secrets-operator  apps/otel-collector
```

**Phase 4 — workload apps.**

```bash
#   apps/loki  apps/vector  apps/grafana  apps/superposition
#   apps/decision-engine  apps/ratelimiter  apps/hyperswitch
```

**Phase 5 — edge.** `load-balancer` before `cloud-cdn` (the CDN attaches to the
LB's backend services).

```bash
#   load-balancer  →  cloud-cdn
#   envoy-proxy  squid-proxy  cloud-monitoring
```

**Phase 6 — firewall rules. Last.**

```bash
terragrunt apply --working-dir firewall-rules
```

`firewall-rules` is the GCP counterpart to the AWS `security-rules` unit: it
opens the cross-service paths the earlier phases assume. Applying it before the
services exist produces rules pointing at absent service accounts and network
tags. Note it depends only on `vpc-network`, so a `run-all` will happily run it
in phase 1 — do not rely on the graph here.

Once every phase has landed once, day-to-day `terragrunt run-all plan` /
`apply` across the whole tree is fine — the ordering problem only bites on a
green-field build.

## Adopting an environment that already exists

`terragrunt.stack.hcl` carries a commented `dev` block showing the shape. It is
commented out because adopting an already-applied environment is not a
generate-and-apply operation:

- **`project_name` must match what was applied.** The catalog defaults to
  `hyps`; an environment built with a different prefix must override it, or the
  first apply renames or recreates essentially every resource.
- **State prefixes must line up.** This root writes state to
  `<env>/<region>/<unit path>`. An environment whose state lives under different
  prefixes needs those objects moved, or the unit will plan a full create.
- **Unit paths must line up.** A hand-written layout that nests units
  differently (e.g. `application-stack/gke` rather than `gke`) changes both the
  state prefix and every `config_path`.
- **Units with no catalog equivalent** need somewhere to live before the old
  tree can be deleted.

Do it one unit at a time, and treat "`terragrunt plan` is a genuine no-op" as
the acceptance criterion for each.

## Known gaps

- The `dependency` graph is thinner than the phase table implies — see above.
- No BYO-VPC stack for GCP, so no self-host path (the AWS
  `catalog/stacks/standalone` is the model).
- 7 of the 9 `custom_images` have no Packer definition.
- Nothing in this tree has been `plan`ned against a real GCP project yet.
