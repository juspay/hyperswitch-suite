# GCP live layer

Internal GCP environments, generated from
[`terraform/gcp/catalog/stacks/internal`](../catalog/stacks/internal/README.md)
by [`terragrunt.stack.hcl`](./terragrunt.stack.hcl).

There is no hand-maintained Terraform here. `terragrunt.stack.hcl` is the only
file to edit; everything under `sandbox/` is generated and then committed.

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

That needs no cloud credentials and no module downloads.

## Before anything can run

All 19 module tags exist, so `init` will resolve. What is left is replacing
every `REPLACE_ME` in `terragrunt.stack.hcl`:

| Placeholder | What it needs |
|---|---|
| `project_id` | the real GCP project |
| `state_bucket` | a globally unique GCS bucket name; Terragrunt creates it on first `init` |
| `vpn_cidr_blocks` | real office / VPN CIDRs. **Left empty, `gke` falls back to an allow-all `master_authorized_networks` entry that must not be applied.** |
| `domains.api`, `domains.grafana` | real hostnames |
| `custom_images.envoy`, `custom_images.squid` | names of images built from `terraform/gcp/packer/{envoy-proxy,squid-proxy}`. These two units will not `apply` without them |
| `bastion_iap_members` | the group(s) or user(s) granted IAP SSH to the bastion |

## Deployment order

Every unit that needs the network or the cluster declares a `dependency`, so
**`terragrunt run-all apply` orders this stack correctly**. From
`terraform/gcp/live/sandbox/asia-south1`:

```bash
terragrunt run-all plan     # review first
terragrunt run-all apply
```

The order it derives:

| Phase | Units | Notes |
|---|---|---|
| 0 | `vpc-network` | also creates the GCS state bucket on first `init` |
| 1 | `application-stack/gke`, `alloydb`, `memorystore-valkey` | independent of each other; `gke` is the long pole (~15–20 min) |
| 2 | `apps/gateway-controller`, `apps/istio`, `apps/argocd`, `apps/external-secrets-operator` | ingress and platform services the workloads attach to |
| 3 | `apps/loki`, `apps/vector`, `apps/grafana`, `apps/superposition`, `apps/hyperswitch` | |
| — | `envoy-proxy`, `squid-proxy`, `artifact-registry`, `bastion-host` | depend only on `vpc-network`, so they run alongside phases 1–3 |
| — | `locker` | depends on `vpc-network` + `gke`; lands with phase 2 |
| last | `firewall-rules` | see the note below |

`firewall-rules` declares only a `vpc-network` dependency, so Terragrunt may
run it early. That is accepted by GCP (a rule may name a tag no instance
carries yet) but means the rules only bite once the proxies and cluster exist.
On a green-field build, re-apply it at the end.

`gateway-controller` has no dependency and may run in phase 0 — that is
correct, it only creates a project-level SSL policy.

To step through by hand instead:

```bash
terragrunt apply --working-dir vpc-network
terragrunt apply --working-dir application-stack/gke
# ...
```

### Two things the stack does not do

- **AlloyDB creates no application databases.** There is no
  `google_alloydb_database` resource — only cluster, instance and user. The
  per-service databases need a psql step against the instance once it is up.
  This applies to both `alloydb` and the vault's own cluster in `locker`.
- **`locker` leaves one manual step.** It creates the Google service account
  and the Workload Identity binding, but does not annotate the Kubernetes
  ServiceAccount — the upstream module does that by shelling out to `kubectl`
  at apply time, which fails against a private cluster and would fail the
  whole apply with it. Run it yourself afterwards:

  ```bash
  kubectl annotate --overwrite sa -n hyperswitch hyperswitch-vault-role \
    iam.gke.io/gcp-service-account=$(terragrunt output -raw service_account_email)
  ```

  Without it Workload Identity does not engage and the pod silently falls back
  to the node's default service account — it does not error.
- **`memorystore-valkey` needs the `memorystore` subnet to be otherwise
  unused.** It uses Private Service Connect, not the PSA peering AlloyDB uses,
  and PSC reserves addresses directly out of that subnet.

## Adopting an environment that already exists

`terragrunt.stack.hcl` carries a commented `dev` block showing the shape. It is
commented out because adopting an already-applied environment is not a
generate-and-apply operation:

- **`project_name` must match what was applied.** The catalog defaults to
  `hyps`; an environment built with a different prefix must override it, or the
  first apply renames or recreates essentially every resource.
- **State prefixes must line up.** This root writes state to
  `<env>/<region>/<unit path>`. An environment whose state lives elsewhere
  needs those objects moved, or the unit plans a full create.
- **Unit paths must line up.** A hand-written layout that nests units
  differently changes both the state prefix and every `config_path`.
- **Units with no catalog equivalent** need somewhere to live before the old
  tree can be deleted.

Do it one unit at a time, and treat "`terragrunt plan` is a genuine no-op" as
the acceptance criterion for each.

## Known gaps

- `load-balancer`, `cloud-cdn`, DNS/TLS and the analytics data layer
  (kafka, cassandra, clickhouse, opensearch) are not in the catalog — see
  [`../catalog/README.md`](../catalog/README.md#scope).
- No BYO-VPC stack for GCP, so no self-host path (the AWS
  `catalog/stacks/standalone` is the model).
- Nothing in this tree has been `plan`ned against a real GCP project yet.
  `hcl validate` resolves references but does not check inputs against module
  variables at apply time.
