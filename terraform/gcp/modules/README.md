# GCP Terraform Modules

GCP equivalents of `terraform/aws/modules/{composition,application-resources}`, built so Hyperswitch can be deployed on GCP with the same module layering the AWS tree uses. See `terraform/aws/ARCHITECTURE.md` for the layering philosophy this tree follows.

Only **composition** and **application-resources** are ported — no `base/` layer, no `live/` roots, no `bootstrap/`, no `cloudfront-resources/`. Where an AWS composition module leans on `../../base/*`, its GCP counterpart calls an **official** registry module instead (`terraform-google-modules/*` / `GoogleCloudPlatform/*` — the Google Cloud Foundation Toolkit). No third-party or community modules are used anywhere in this tree.

## Why no `base/` layer

Only 5 of the 23 AWS composition modules touch `base/` at all, and each has a direct official-module replacement:

| AWS composition | `base/` modules used | Official GCP replacement |
|---|---|---|
| `vpc-network` | vpc, subnet ×14, route-table ×13, network-acl, vpc-endpoint, security-group | `terraform-google-modules/network` (root module handles VPC + subnets + routes + firewall in one call) |
| `squid-proxy` | s3-bucket ×2, iam-role, nlb, target-group, nlb-listener ×2, launch-template, asg | `cloud-storage//modules/simple_bucket`, `service-accounts`, `vm//modules/{instance_template,mig}`, `lb-internal` |
| `cassandra` | lambda, api-gateway | `GoogleCloudPlatform/cloud-functions` (a single HTTP-triggered Gen2 function needs no separate API Gateway resource on GCP) |
| `terraform-backend` | s3-bucket, dynamodb-table | `cloud-storage//modules/simple_bucket` (GCS backend locks natively — no lock-table equivalent) |
| `eks` | eks | `kubernetes-engine//modules/private-cluster` |

`application-resources/` never touched `base/` on the AWS side either.

## Module map

### composition/ (23 modules)

| GCP module | AWS module | Built from |
|---|---|---|
| `vpc-network` | `vpc-network` | `network`, `cloud-router`, `cloud-nat`, `network//modules/private-service-access` |
| `gke` | `eks` | `kubernetes-engine//modules/private-cluster` |
| `gke-kubernetes-resources` | `eks-kubernetes-resources` | `kubernetes`/`helm` providers direct |
| `cloud-sql` | `database` | `sql-db//modules/postgresql`, `kms` |
| `memorystore` | `elasticache` | `memorystore` |
| `cloud-dns` | `route53` | `cloud-dns` |
| `artifact-registry` | `ecr` | raw `google_artifact_registry_repository` |
| `certificate-manager` | `acm` | raw `google_certificate_manager_*` (no official module exists) |
| `cloud-cdn` | `cloudfront` | raw `google_compute_backend_bucket`/URL map/proxy, `cloud-storage` |
| `cloud-monitoring` | `cloudwatch` | raw `google_monitoring_*`, `log-export` |
| `filestore` | `efs` | raw `google_filestore_instance`/`google_filestore_backup` (no official module exists) |
| `pubsub` | `sns` | `pubsub` |
| `load-balancer` | `load-balancer` | `lb-http` / `lb-internal` |
| `gcs-backend` | `terraform-backend` | `cloud-storage//modules/simple_bucket` |
| `firewall-rules` | `security-rules` | `network//modules/firewall-rules` |
| `bastion-host` | `jump-host` | `bastion-host`, `cloud-storage`, `log-export` |
| `envoy-proxy` | `envoy-proxy` | `vm//modules/{instance_template,mig}`, `lb-http`, `cloud-armor`, `secret-manager` |
| `squid-proxy` | `squid-proxy` | `vm//modules/{instance_template,mig}`, `lb-internal`, `cloud-storage` |
| `kafka` | `kafka` | `vm//modules/{instance_template,compute_instance}`, `service-accounts` |
| `cassandra` | `cassandra` | `vm//modules/{instance_template,compute_instance}`, `cloud-functions` |
| `clickhouse` | `clickhouse` | `vm//modules/{instance_template,umig,compute_instance}`, `lb-internal` |
| `opensearch` | `opensearch` | `vm//modules/{instance_template,umig}`, `lb-internal` |
| `locker` | `locker` | `vm//modules/{instance_template,umig}`, `kms`, `lb-internal`, `../cloud-sql` |

### application-resources/ (14 modules)

| GCP module | AWS module | Notes |
|---|---|---|
| `gke-workload-identity` | `eks-iam` | Generic Workload Identity + optional bucket variant |
| `shared-iam-roles` | `shared-policy` | Custom IAM roles, `for_each` over `var.roles` |
| `gateway-controller` | `alb-controller` | GKE's Gateway/Ingress controller is built in — no Helm chart to install |
| `istio` | `istio` | Same istio-release Helm charts |
| `argocd` | `argocd` | Cross-project impersonation instead of cross-account assume-role |
| `external-secrets-operator` | `external-secrets-operator` | Secret Manager instead of Secrets Manager |
| `hyperswitch` | `hyperswitch` | KMS, GCS buckets, Secret Manager (SMTP), Cloud Functions, cross-project impersonation |
| `loki` | `loki` | GCS + Pub/Sub notification instead of S3 + SNS/SQS |
| `vector` | `vector` | GCS + Pub/Sub topic/subscription instead of S3 + SQS |
| `otel-collector` | `otel-collector` | Workload Identity + Cloud Operations roles |
| `grafana` | `grafana` | `../../composition/cloud-sql` via a single `database_config` object |
| `superposition` | `superposition` | Same `database_config` object shape as `grafana` |
| `decision-engine` | `decision-engine` | Secret Manager instead of SES |
| `ratelimiter` | `ratelimiter` | `../../composition/memorystore` + `../../composition/firewall-rules` |

## Intentional gaps and divergences

- **No NACL equivalent** in `vpc-network` — GCP firewall rules are stateful, making NACLs redundant.
- **No DynamoDB-style lock table** in `gcs-backend` — the GCS Terraform backend locks natively via object generation.
- **CloudFront Functions have no Cloud CDN equivalent** — `cloud-cdn` has no edge-compute hook; the nearest GCP-native path is a Cloud Run/Cloud Functions origin.
- **SES has no GCP equivalent** — `hyperswitch` and `decision-engine` take a `smtp_secret_id` pointing at a Secret Manager secret instead.
- **GKE's Gateway API resources (Gateway/HTTPRoute) are not created by Terraform** in `istio` or `gateway-controller` — they're Kubernetes-native custom resources with no first-class `hashicorp/kubernetes` provider type, so they're left to your GitOps/kubectl flow, the same boundary the rest of this tree draws between infrastructure and Kubernetes-native config.
- **Relative paths, not pinned `git::` refs**, for cross-module composition (`locker` → `../cloud-sql`, `grafana`/`superposition` → `../../composition/cloud-sql`, `ratelimiter` → `../../composition/{memorystore,firewall-rules}`). The AWS tree pins `git::...?ref=database-v0.1.6`; this tree has no released tags yet — switch once it does.
- **One `database_config` object shape**, used identically by `grafana` and `superposition` — the AWS tree has `grafana` and `superposition` calling the same database module with two different interface styles (flattened vars vs. an object); this tree picked one and kept both callers consistent.
- **VM-tier modules (`kafka`, `cassandra`, `clickhouse`, `opensearch`, `locker`) are Compute Engine ports, not managed services** — same as their AWS counterparts, which are self-managed EC2 fleets with a pre-baked AMI. There's no first-party managed OpenSearch/Elasticsearch on GCP; the alternative is Elastic Cloud on GCP Marketplace or routing that workload to BigQuery/Log Analytics instead, which would be a different module shape entirely.
- **Uniform provider version floor.** All 37 modules pin `google >= 6.0` and `terraform >= 1.5.0` (`google-beta >= 6.0` where the GKE/network modules need it). The AWS tree has version drift across its modules (`>= 5.0` / `~> 5.0` / `>= 6.32.1`); this tree does not reproduce that.

## Registry modules used (verified against the Terraform Registry, pinned by exact version)

`terraform-google-modules/network` 18.1.2 · `kubernetes-engine` 44.3.0 · `cloud-storage` 12.3.0 · `sql-db` 28.1.0 · `memorystore` 16.1.1 · `vm` 15.2.1 · `iam` 8.2.0 · `service-accounts` 4.7.0 · `lb-http` (`GoogleCloudPlatform/lb-http`) 14.2.0 · `lb-internal` 7.1.0 · `cloud-dns` 7.1.0 · `pubsub` 8.8.0 · `kms` 4.1.2 · `cloud-router` 9.0.0 · `cloud-nat` 7.0.0 · `bastion-host` 9.0.0 · `log-export` 11.1.0 · `cloud-operations` 0.7.0 · `GoogleCloudPlatform/artifact-registry` 0.8.2 · `GoogleCloudPlatform/secret-manager` 0.9.0 · `GoogleCloudPlatform/cloud-armor` 8.1.1 · `GoogleCloudPlatform/cloud-functions` 0.9.0.

## Conventions

Same as the AWS tree (`terraform/aws/modules/.terraform-docs.yml`, file layout, `locals.tf`/`common_labels` pattern) with two GCP-specific adjustments: `common_tags` → `common_labels` (GCP label values are lowercase-alphanumeric-plus-`-_` only), and READMEs are terraform-docs generated (`just gen-docs`) exactly like the AWS side.
