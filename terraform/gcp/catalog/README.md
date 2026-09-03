# GCP Terragrunt Catalog — units

Reusable Terragrunt **units** for deploying Hyperswitch on GCP. Each unit is a
parameterized `terragrunt.hcl` wrapping exactly one module from
`terraform/gcp/modules` at a pinned release tag.

```
terraform/gcp/catalog/units/
├── vpc-network/          ├── envoy-proxy/        ├── artifact-registry/
├── alloydb/              ├── squid-proxy/        ├── bastion-host/
├── memorystore-valkey/   ├── locker/             ├── firewall-rules/
└── application-stack/
    ├── gke/
    └── apps/{argocd, external-secrets-operator, gateway-controller, grafana,
               hyperswitch, istio, loki, superposition, vector}
```

19 units. This mirrors the AWS catalog proposed in
[PR #302](https://github.com/juspay/hyperswitch-suite/pull/302) — same unit
skeleton, same tag-pinning discipline.

> **This PR ships units only.** The stack that composes them
> (`catalog/stacks/internal`, including the `root.hcl` every unit includes) and
> the generated live layer follow in a separate PR, once these units are
> tagged.

## Unit skeleton

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")   # travels with the *stack*
  expose = true
}

dependency "gke" {
  config_path  = "../../gke"
  mock_outputs = { ... }
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/application-resources/<name>?ref=<tag>"
}

inputs = { ... }
```

### The root contract

Units read exactly five things from the stack's `root.hcl`. This is the whole
interface between a unit and whatever composes it — adding a local is cheap,
renaming one is not:

| Local | Used by |
|---|---|
| `include.root.locals.environment.short` | every unit (resource naming) |
| `include.root.locals.project_name` | every unit (resource naming) |
| `include.root.locals.project_id` | every unit |
| `include.root.locals.region` | every unit |
| `include.root.locals.vpn_cidr_blocks` | `gke` only |

### Stack values

Everything else that varies per environment arrives through Terragrunt Stacks
`values`, so nothing environment-specific is hardcoded in a unit:

| Value | Consumed by |
|---|---|
| `vpc_cidr_prefix`, `gke_pods_secondary_range_cidr`, `gke_services_secondary_range_cidr` | `vpc-network`; the first two also by `squid-proxy` and `firewall-rules` |
| `machine_types` | `gke`, `bastion-host` |
| `domains` (`api`, `grafana`) | `istio`, `grafana`, `hyperswitch` |
| `custom_images` (`envoy`, `squid`) | `envoy-proxy`, `squid-proxy` |
| `bastion_iap_members` | `bastion-host` |
| `smtp_secret_id` | `hyperswitch` |
| `alloydb`, `valkey`, `locker` (optional maps) | the matching data units |

### Dependency layout

Unit `path`s in the consuming stack are load-bearing — `config_path` values are
written against this layout:

```
vpc-network                      alloydb              -> ../vpc-network
memorystore-valkey               envoy-proxy          -> ../vpc-network
artifact-registry                squid-proxy          -> ../vpc-network
bastion-host                     firewall-rules       -> ../vpc-network
locker                           -> ../vpc-network, ../application-stack/gke
application-stack/gke            -> ../../vpc-network
application-stack/apps/<name>    -> ../../gke, ../../../vpc-network
```

## Scope

A unit exists here only if its module is published on `main`. All 19 pins
resolve to existing tags — `scripts/ci/check-gcp-pins.sh` enforces it.

| Excluded | Why |
|---|---|
| `load-balancer`, `cloud-cdn`, `cloud-dns`, `certificate-manager`, `pubsub` | published, but out of scope for the application stack |
| `kafka`, `cassandra`, `clickhouse`, `opensearch`, `filestore`, `cloud-monitoring`, `gke-kubernetes-resources` | no module on `main` |
| `apps/decision-engine`, `apps/otel-collector`, `apps/ratelimiter` | no module on `main` — add back when they land |
| `gke-workload-identity` | needs no unit; every app module calls it as a nested Terraform module |
| `shared-iam-roles` | nothing consumes it yet |

## Pinned module tags

| Unit | Module | Tag |
|---|---|---|
| `vpc-network` | `composition/vpc-network` | `gcp-vpc-network-v0.1.0` |
| `alloydb` | `composition/alloydb` | `gcp-alloydb-v0.1.0` |
| `memorystore-valkey` | `composition/memorystore-valkey` | `gcp-memorystore-valkey-v0.1.0` |
| `artifact-registry` | `composition/artifact-registry` | `gcp-artifact-registry-v0.1.0` |
| `bastion-host` | `composition/bastion-host` | `gcp-bastion-host-v0.1.0` |
| `locker` | `composition/locker` | `gcp-locker-v0.1.0` |
| `firewall-rules` | `composition/firewall-rules` | `gcp-firewall-rules-v0.1.0` |
| `envoy-proxy` | `composition/envoy-proxy` | `gcp-envoy-proxy-v0.1.0` |
| `squid-proxy` | `composition/squid-proxy` | `gcp-squid-proxy-v0.1.0` |
| `application-stack/gke` | `composition/gke` | `gcp-gke-v0.1.0` |
| `…/apps/argocd` | `application-resources/argocd` | `gcp-apps-argocd-v0.1.0` |
| `…/apps/external-secrets-operator` | `application-resources/external-secrets-operator` | `gcp-apps-eso-v0.1.0` |
| `…/apps/gateway-controller` | `application-resources/gateway-controller` | `gcp-apps-gcp-v0.1.0` |
| `…/apps/grafana` | `application-resources/grafana` | `gcp-apps-grafana-v0.1.0` |
| `…/apps/hyperswitch` | `application-resources/hyperswitch` | `gcp-apps-hyperswitch-v0.1.0` |
| `…/apps/istio` | `application-resources/istio` | `gcp-apps-istio-v0.1.0` |
| `…/apps/loki` | `application-resources/loki` | `gcp-apps-loki-v0.1.0` |
| `…/apps/superposition` | `application-resources/superposition` | `gcp-apps-superposition-v0.1.0` |
| `…/apps/vector` | `application-resources/vector` | `gcp-apps-vector-v0.1.0` |

### Two tag names to clean up

Both are published and pinned as-is so the catalog works today, but neither
follows the `gcp-apps-<module>-vX.Y.Z` grammar the other eight use:

- `gcp-apps-eso-v0.1.0` abbreviates `external-secrets-operator`.
- **`gcp-apps-gcp-v0.1.0` is the gateway-controller module** — that reads like
  a mis-typed tag name. Re-tag as `gcp-apps-gateway-controller-vX.Y.Z` and
  repoint the unit.

## Versioning

Module tags:

- composition module `<name>` → `gcp-<name>-vX.Y.Z`
- application-resources module `<name>` → `gcp-apps-<name>-vX.Y.Z`

Unit tags follow the AWS grammar,
`unit/<name>-v<module-version>-v<unit-revision>` — the wrapped module's tag is
pinned inside the unit, and the trailing revision bumps whenever the unit file
changes. Tagging these units is the step between this PR and the stack PR that
consumes them by ref.

## CI

`.github/workflows/terragrunt-validate-gcp.yml`:

- `terragrunt hcl format --check` on the catalog
- `scripts/ci/check-sensitive.sh terraform/gcp` — no internal identifiers or
  credential-shaped strings may land in this repo
- `scripts/ci/check-gcp-pins.sh` — every `?ref=` is a tag of the expected shape
  and that tag exists

`terragrunt stack generate` and `terragrunt hcl validate` are added in the
stack PR; they need a stack and a live tree to run against.
