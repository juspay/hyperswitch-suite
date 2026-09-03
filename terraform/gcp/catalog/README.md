# GCP Terragrunt Catalog

Reusable Terragrunt units and stacks for deploying the Hyperswitch
application stack on GCP.

```
terraform/gcp/catalog/
├── units/
│   ├── vpc-network/            # foundation — everything depends on it
│   ├── alloydb/                # Postgres
│   ├── memorystore-valkey/     # cache
│   ├── envoy-proxy/            # ingress proxy (custom GCE image)
│   ├── squid-proxy/            # egress proxy (custom GCE image)
│   ├── artifact-registry/      # container images
│   ├── bastion-host/           # IAP SSH entry point
│   ├── locker/                 # card vault: database + identity + CMEK
│   ├── firewall-rules/         # cross-unit connectivity (apply last)
│   └── application-stack/
│       ├── gke/
│       └── apps/               # 9 workloads on the cluster
└── stacks/
    └── internal/               # sandbox / dev / pre-prod / prod
```

19 units. This mirrors the AWS catalog proposed in
[PR #302](https://github.com/juspay/hyperswitch-suite/pull/302) — same unit
skeleton, same tag-pinning discipline, same CI shape.

## Scope

**A unit exists here only if its module is published on `main`.** Every one of
the 19 pins resolves to a real tag; `scripts/ci/check-gcp-pins.sh` enforces it.

Not in the catalog:

| Excluded | Why |
|---|---|
| `load-balancer`, `cloud-cdn`, `cloud-dns`, `certificate-manager`, `pubsub` | published on `main`, but outside this stack's scope |
| `kafka`, `cassandra`, `clickhouse`, `opensearch`, `filestore`, `cloud-monitoring`, `gke-kubernetes-resources` | no module on `main` |
| `apps/decision-engine`, `apps/otel-collector`, `apps/ratelimiter` | no module on `main` — add back when they land |
| `gke-workload-identity` | needs no unit; every app module calls it as a nested Terraform module |
| `shared-iam-roles` | nothing consumes it yet |

`vpc-network` stays despite being a network unit: every other unit depends on
it directly or through `gke`, so dropping it would leave the graph dangling.

### Edge proxies

`envoy-proxy` (ingress) and `squid-proxy` (egress) each need a pre-baked custom
GCE image. `terraform/gcp/packer/{envoy-proxy,squid-proxy}` has the Packer
definitions — these are the only two units in the catalog with an image
prerequisite, which is why the other image-dependent units (kafka, cassandra,
clickhouse, opensearch, locker) are also the ones with no published module.

`squid-proxy` restricts its internal LB to `ilb_source_ranges`, and the
`firewall-rules` unit carries the matching `gke-to-squid-egress` rule. Both
derive from the same two stack values `vpc-network` builds the GKE ranges
from, so all three cannot drift apart.

### The card vault

`composition/locker` was rewritten upstream and no longer provisions a VM
fleet from a baked image. The vault runs on GKE through the same Helm flow as
every other app; the unit creates only what Kubernetes cannot create for
itself — a dedicated AlloyDB cluster (separate from the shared one, so card
data keeps its own PCI-DSS scope), the Workload Identity binding, and the CMEK
key.

Two things it deliberately does not do, both documented in the unit: it does
not annotate the Kubernetes ServiceAccount (that would shell out to `kubectl`
at apply time and fail against a private cluster), and it does not create the
`locker` database inside the AlloyDB cluster (no such Terraform resource
exists). Both are one-line manual steps.

### Database and cache

The catalog targets `composition/alloydb` and `composition/memorystore-valkey`
— what is published and what the live GCP environment actually runs. Earlier
drafts pointed at `composition/cloud-sql` and `composition/memorystore`, which
are not on `main`; those units were rewritten, not just repointed, because the
module interfaces differ.

## Units

Each unit follows the same skeleton:

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

Units read exactly five things from the stack's `root.hcl` —
`environment.short`, `project_name`, `project_id`, `region` and
`vpn_cidr_blocks` (gke only). Everything else that varies per environment
arrives through Terragrunt Stacks `values`.

## Pinned tags

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

- composition module `<name>` → `gcp-<name>-vX.Y.Z`
- application-resources module `<name>` → `gcp-apps-<name>-vX.Y.Z`

The AWS catalog additionally tags the *units* themselves
(`unit/<name>-v<module-version>-v<unit-revision>`). GCP units are not tagged
yet — they are consumed by path from `terraform/gcp/live` inside this repo.
Adopt the AWS grammar when a consumer outside this repo needs to pin a unit.

## Consuming

- **Internal environments**: [`terraform/gcp/live/terragrunt.stack.hcl`](../live/terragrunt.stack.hcl)
  targets `stacks/internal` — see [`live/README.md`](../live/README.md).
- **By git ref**: `source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/<unit>?ref=<tag>"`.

## CI

`.github/workflows/terragrunt-validate-gcp.yml`:

- `terragrunt hcl format --check` on the catalog and the live tree
- `terragrunt stack generate` must produce no diff against the committed tree
- `terragrunt hcl validate` over the generated tree — resolves every local,
  `values` and `dependency` reference in all 19 units
- `scripts/ci/check-sensitive.sh terraform/gcp`
- `scripts/ci/check-gcp-pins.sh` — every `?ref=` is a tag of the right shape
  and that tag exists
