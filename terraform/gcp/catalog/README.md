# GCP Terragrunt Catalog

Reusable Terragrunt units and stacks for deploying Hyperswitch on GCP.

```
terraform/gcp/catalog/
├── units/     # one directory per unit — a parameterized terragrunt.hcl
│              # wrapping a composition/application-resources module by git tag
└── stacks/
    └── internal/   # sandbox / dev / pre-prod / prod — creates its own VPC,
                    # wires every unit (see its README)
```

This mirrors the AWS catalog introduced in
[PR #302](https://github.com/juspay/hyperswitch-suite/pull/302); the unit
skeleton, tag-pinning discipline and CI shape are deliberately the same so the
two clouds stay reviewable side by side.

## Units

34 units — 22 composition, 12 application-resources. Each follows the same
skeleton:

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")   # travels with the *stack*
  expose = true
}

dependency "vpc" {
  config_path  = "../vpc-network"
  mock_outputs = { ... }
}

terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/modules/composition/<name>?ref=<tag>"
}

inputs = { ... }
```

Units read exactly five things from the stack's `root.hcl`:

| Local | Used by |
|---|---|
| `include.root.locals.environment.short` | every unit (resource naming) |
| `include.root.locals.project_name` | every unit (resource naming) |
| `include.root.locals.project_id` | every unit (GCP project) |
| `include.root.locals.region` | every unit |
| `include.root.locals.vpn_cidr_blocks` | `gke` only |

Everything else that varies per environment arrives through Terragrunt Stacks
`values` — `vpc_cidr_prefix`, `domains`, `custom_images`, `machine_types`,
`bastion_iap_members`, `alert_notification_email`, `smtp_secret_id`. Nothing
environment-specific is hardcoded in a unit.

### Two modules deliberately have no unit

- **`gke-workload-identity`** doesn't need one. Every application-resources
  module that needs a Google service account plus a Workload Identity binding
  already calls it as a nested Terraform module — it is embedded at the module
  level, not the live-layer level.
- **`shared-iam-roles`** is deferred. No GCP unit consumes it yet. Add
  `units/shared-iam-roles/` (the same shape as any other no-dependency unit)
  once something needs a shared custom IAM role.

## Consuming

- **Internal environments**: [`terraform/gcp/live/terragrunt.stack.hcl`](../live/terragrunt.stack.hcl)
  targets `stacks/internal` — see [`live/README.md`](../live/README.md).
- **By git ref**: a stack file in another repository can pin this catalog with
  `source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/gcp/catalog/units/<unit>?ref=<tag>"`.

## Versioning

Module tags follow the GCP grammar already in use in this repository:

- composition module `<name>` → `gcp-<name>-vX.Y.Z`
- application-resources module `<name>` → `gcp-apps-<name>-vX.Y.Z`

`scripts/ci/check-gcp-pins.sh` enforces that every `?ref=` in this directory is
a tag of that shape **and** that the tag exists.

> The AWS catalog additionally tags the *units* themselves
> (`unit/<name>-v<module-version>-v<unit-revision>`). GCP units are not tagged
> yet — they are consumed by path from `terraform/gcp/live` inside this repo.
> Adopt the AWS grammar when a consumer outside this repo needs to pin a unit.

## Module tags this catalog requires

10 of the 34 tags exist today. The remaining 24 modules live only on the
unmerged `feat/gcp-terraform-modules` branch — **they must be merged to `main`
and tagged before any of this can `init`.** `check-gcp-pins.sh` prints exactly
this list.

| Unit | Module | Pinned tag | Tag status |
|---|---|---|---|
| `vpc-network` | `composition/vpc-network` | `gcp-vpc-network-v0.1.0` | exists |
| `gke` | `composition/gke` | `gcp-gke-v0.1.0` | exists |
| `artifact-registry` | `composition/artifact-registry` | `gcp-artifact-registry-v0.1.0` | exists |
| `cloud-cdn` | `composition/cloud-cdn` | `gcp-cloud-cdn-v0.1.0` | exists |
| `envoy-proxy` | `composition/envoy-proxy` | `gcp-envoy-proxy-v0.1.0` | exists |
| `firewall-rules` | `composition/firewall-rules` | `gcp-firewall-rules-v0.1.0` | exists |
| `load-balancer` | `composition/load-balancer` | `gcp-load-balancer-v0.1.0` | exists |
| `squid-proxy` | `composition/squid-proxy` | `gcp-squid-proxy-v0.1.0` | exists |
| `apps/hyperswitch` | `application-resources/hyperswitch` | `gcp-apps-hyperswitch-v0.1.0` | exists |
| `apps/superposition` | `application-resources/superposition` | `gcp-apps-superposition-v0.1.0` | exists |
| `bastion-host` | `composition/bastion-host` | `gcp-bastion-host-v0.1.0` | **missing** |
| `cassandra` | `composition/cassandra` | `gcp-cassandra-v0.1.0` | **missing** |
| `certificate-manager` | `composition/certificate-manager` | `gcp-certificate-manager-v0.1.0` | **missing** |
| `clickhouse` | `composition/clickhouse` | `gcp-clickhouse-v0.1.0` | **missing** |
| `cloud-dns` | `composition/cloud-dns` | `gcp-cloud-dns-v0.1.0` | **missing** |
| `cloud-monitoring` | `composition/cloud-monitoring` | `gcp-cloud-monitoring-v0.1.0` | **missing** |
| `cloud-sql` | `composition/cloud-sql` | `gcp-cloud-sql-v0.1.0` | **missing** |
| `filestore` | `composition/filestore` | `gcp-filestore-v0.1.0` | **missing** |
| `gke-kubernetes-resources` | `composition/gke-kubernetes-resources` | `gcp-gke-kubernetes-resources-v0.1.0` | **missing** |
| `kafka` | `composition/kafka` | `gcp-kafka-v0.1.0` | **missing** |
| `locker` | `composition/locker` | `gcp-locker-v0.1.0` | **missing** |
| `memorystore` | `composition/memorystore` | `gcp-memorystore-v0.1.0` | **missing** |
| `opensearch` | `composition/opensearch` | `gcp-opensearch-v0.1.0` | **missing** |
| `pubsub` | `composition/pubsub` | `gcp-pubsub-v0.1.0` | **missing** |
| `apps/argocd` | `application-resources/argocd` | `gcp-apps-argocd-v0.1.0` | **missing** |
| `apps/decision-engine` | `application-resources/decision-engine` | `gcp-apps-decision-engine-v0.1.0` | **missing** |
| `apps/external-secrets-operator` | `application-resources/external-secrets-operator` | `gcp-apps-external-secrets-operator-v0.1.0` | **missing** |
| `apps/gateway-controller` | `application-resources/gateway-controller` | `gcp-apps-gateway-controller-v0.1.0` | **missing** |
| `apps/grafana` | `application-resources/grafana` | `gcp-apps-grafana-v0.1.0` | **missing** |
| `apps/istio` | `application-resources/istio` | `gcp-apps-istio-v0.1.0` | **missing** |
| `apps/loki` | `application-resources/loki` | `gcp-apps-loki-v0.1.0` | **missing** |
| `apps/otel-collector` | `application-resources/otel-collector` | `gcp-apps-otel-collector-v0.1.0` | **missing** |
| `apps/ratelimiter` | `application-resources/ratelimiter` | `gcp-apps-ratelimiter-v0.1.0` | **missing** |
| `apps/vector` | `application-resources/vector` | `gcp-apps-vector-v0.1.0` | **missing** |

### Naming conflict to settle when merging

`main` already carries `composition/alloydb` and `composition/memorystore-valkey`
(both tagged, both used by the live GCP dev environment in `hyperswitch-infra`).
The `feat/gcp-terraform-modules` branch carries `composition/cloud-sql` and
`composition/memorystore` instead, and this catalog pins the latter pair.

Shipping both pairs means two ways to provision the same thing. Decide which
survives before cutting tags, and repoint `units/cloud-sql` /
`units/memorystore` if the `alloydb` / `memorystore-valkey` modules win.

## CI

- `.github/workflows/terragrunt-validate-gcp.yml`
  - `terragrunt hcl format --check` on the catalog and live tree
  - `terragrunt stack generate` must produce no diff against the committed tree
  - `terragrunt hcl validate` over the generated tree — resolves every local,
    `values` and `dependency` reference in all 34 units
  - `scripts/ci/check-sensitive.sh terraform/gcp`
  - `scripts/ci/check-gcp-pins.sh` (non-blocking until the 24 tags are cut)
