# GCP live layer

This directory holds the GCP environments, generated from
[`terraform/gcp/catalog/stacks/dev`](../catalog/stacks/dev/README.md)
by [`terragrunt.stack.hcl`](./terragrunt.stack.hcl).

There is no hand-maintained Terraform here. `terragrunt.stack.hcl` is the only
file to edit; everything else under `sandbox/` and `dev/` is generated and then
committed.

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

All 18 module tags exist, so `init` will resolve. What is left is replacing
every `REPLACE_ME` in `terragrunt.stack.hcl`:

| Placeholder | What it needs |
|---|---|
| `project_id` | the real GCP project |
| `state_bucket` | a globally unique GCS bucket name; Terragrunt creates it on first `init` |
| `vpn_cidr_blocks` | real office / VPN CIDRs. **Left empty, `gke` falls back to an allow-all `master_authorized_networks` entry that must not be applied.** |
| `domains.api`, `domains.grafana` | real hostnames |
| `custom_images.envoy`, `custom_images.squid` | names of images built from `terraform/gcp/packer/{envoy-proxy,squid-proxy}`. These two units will not `apply` without them |
| `bastion_iap_members` | the group(s) or user(s) granted IAP SSH to the bastion |

## Values

Every value is supplied in the `values = { ... }` block of each `stack` in
`terragrunt.stack.hcl`. Required values are enforced by the stack's `root.hcl;
optional values fall back to unit defaults.

### Required values

| Value | Used by | Notes |
|---|---|---|
| `env` | `root.hcl` | one of `sandbox`, `dev`, `pre-prod`, `prod` |
| `region` | `root.hcl` | also the GCS state bucket location |
| `project_id` | `root.hcl` | the GCP project |
| `state_bucket` | `root.hcl` | globally unique; created on first `init` unless `skip_bucket_creation` |
| `vpc_cidr_prefix` | `vpc-network`, `squid-proxy`, `firewall-rules` | e.g. `"10.64"` |
| `gke_pods_secondary_range_cidr` | `vpc-network`, `squid-proxy`, `firewall-rules` | pod range |
| `gke_services_secondary_range_cidr` | `vpc-network` | service range |
| `machine_types.gke_system_pool` | `gke` | node pool machine type |
| `machine_types.gke_generic_compute` | `gke` | node pool machine type |
| `machine_types.bastion` | `bastion-host` | bastion machine type |
| `domains.api` | `istio`, `hyperswitch` | public hostname for API traffic |
| `domains.grafana` | `grafana` | public hostname for Grafana |
| `custom_images.envoy` | `envoy-proxy` | image name / family |
| `custom_images.squid` | `squid-proxy` | image name / family |
| `bastion_iap_members` | `bastion-host` | list of IAM identities with IAP SSH |

### Optional values

| Value | Used by | Default / effect |
|---|---|---|
| `project_name` | `root.hcl` | `hyps`; resource name prefix |
| `skip_bucket_creation` | `root.hcl` | `false`; set `true` to reuse an existing bucket |
| `vpn_cidr_blocks` | `root.hcl`, `gke` | `[]`; empty lets `gke` fall back to unsafe allow-all placeholder |
| `subnet_cidrs` | `vpc-network` | omitted — unit derives from `vpc_cidr_prefix` |
| `network_options` | `vpc-network` | omitted — unit defaults |
| `gke_master_ipv4_cidr_block` | `gke` | unit default |
| `gke_deletion_protection` | `gke` | unit default |
| `alloydb` | `alloydb` | unit default |
| `valkey` | `memorystore-valkey` | unit default |
| `locker` | `locker` | unit default |
| `smtp_secret_id` | `hyperswitch` | `null` disables SMTP wiring |
| `unit_config.<app>` | each app unit | optional per-app overrides |

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
| 1 | `application-stack/gke`, `alloydb`, `memorystore-valkey` | independent of each other; `gke` is the long pole |
| 2 | `apps/gateway-controller`, `apps/istio`, `apps/argocd`, `apps/external-secrets-operator` | ingress and platform services |
| 3 | `apps/loki`, `apps/vector`, `apps/grafana`, `apps/superposition`, `apps/hyperswitch` | workload apps |
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

## Adopting an environment that already exists

The `dev` block in `terragrunt.stack.hcl` is commented out because adopting an
already-applied environment is not a generate-and-apply operation:

- **`project_name` must match what was applied.** The catalog defaults to
  `hyps`; an environment built with a different prefix must override it, or the
  first apply renames or recreates essentially every resource.
- **State prefixes must line up.** This root writes state to
  `<env>/<region>/<unit path>`. An environment whose state lives elsewhere
  needs those objects moved, or the unit plans a full create.
- **Unit paths must line up.** A hand-written layout that nests units
  differently changes both the state prefix and every `config_path`.

Do it one unit at a time, and treat "`terragrunt plan` is a genuine no-op" as
the acceptance criterion for each.

## Known gaps

- `load-balancer`, `cloud-cdn`, DNS/TLS and the analytics data layer
  (kafka, cassandra, clickhouse, opensearch) are not in the catalog — see
  [`../catalog/README.md`](../catalog/README.md#scope).
- Nothing in this tree has been `plan`ned against a real GCP project yet.
  `hcl validate` resolves references but does not check inputs against module
  variables at apply time.
