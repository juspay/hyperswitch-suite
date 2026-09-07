# Changelog

All notable changes to the **Hyperswitch Suite** (the Terraform/Terragrunt infrastructure that deploys Hyperswitch) are documented here.

> For application-level changes — connectors, payment flows, web SDK, control center — see the upstream [juspay/hyperswitch](https://github.com/juspay/hyperswitch) release notes. Each suite release below lists the upstream app version it was validated against.

## Compatibility

A "suite release" is validated against a specific upstream app-server release and a matrix of companion component releases. The app container image tag and Helm values are managed in the GitOps layer (ArgoCD/Helm) outside this repository; the suite itself does not pin the router image.

| Suite | Date | Hyperswitch App | Control Center | Web Client | Card Vault | Encryption Service | WooCommerce Plugin |
|---|---|---|---|---|---|---|---|
| v1.21 | 2026-08-18 | [v1.126.0](https://github.com/juspay/hyperswitch/releases/tag/v1.126.0) | [v1.38.7](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.7) | [v0.133.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.133.0) | [v0.9.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.9.0) | [v0.1.14](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.14) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.20 | 2026-07-09 | [v1.125.0](https://github.com/juspay/hyperswitch/releases/tag/v1.125.0) | [v1.38.6](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.6) | [v0.132.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.132.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.13](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.13) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.19 | 2026-06-29 | [v1.124.0](https://github.com/juspay/hyperswitch/releases/tag/v1.124.0) | [v1.38.5](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.5) | [v0.132.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.132.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.18 | 2026-05-19 | [v1.123.1](https://github.com/juspay/hyperswitch/releases/tag/v1.123.1) | [v1.38.4](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.4) | [v0.131.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.131.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.17 | 2026-04-13 | [v1.123.0](https://github.com/juspay/hyperswitch/releases/tag/v1.123.0) | [v1.38.3](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.3) | [v0.130.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.130.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.16 | 2026-3-24 | [v1.122.0](https://github.com/juspay/hyperswitch/releases/tag/v1.122.0) | [v1.38.2](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.2) | [v0.129.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.129.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.15 | 2026-2-24 | [v1.121.0](https://github.com/juspay/hyperswitch/releases/tag/v1.121.0) | [v1.38.2](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.2) | [v0.129.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.129.0) | [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0) | [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12) | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.14 | 2025-11-27 | [v1.120.0](https://github.com/juspay/hyperswitch/releases/tag/v1.120.0) | [v1.37.8](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.8) | [v0.127.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.127.0) | [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.13 | 2025-11-04 | [v1.119.0](https://github.com/juspay/hyperswitch/releases/tag/v1.119.0) | [v1.37.7](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.7) | [v0.127.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.127.0) | [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.12 | 2025-10-14 | [v1.118.0](https://github.com/juspay/hyperswitch/releases/tag/v1.118.0) | [v1.37.5](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.5) | [v0.126.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.126.0) | [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.11 | 2025-09-11 | [v1.117.0](https://github.com/juspay/hyperswitch/releases/tag/v1.117.0) | [v1.37.4](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.4) | [v0.126.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.126.0) | [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.10 | 2025-08-05 | [v1.116.0](https://github.com/juspay/hyperswitch/releases/tag/v1.116.0) | [v1.37.3](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.3) | [v0.125.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.125.0) | [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.9 | 2025-07-02 | [v1.115.0](https://github.com/juspay/hyperswitch/releases/tag/v1.115.0) |  |  |  |  |  |
| v1.8 | 2025-04-09 | [v1.114.0](https://github.com/juspay/hyperswitch/releases/tag/v1.114.0) | [v1.37.1](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.1) | [v0.121.2](https://github.com/juspay/hyperswitch-web/releases/tag/v0.121.2) | [v 0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.7 | 2025-03-04 | [v1.113.0](https://github.com/juspay/hyperswitch/releases/tag/v1.113.0) | [v1.36.1](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.36.1) | [v0.109.2](https://github.com/juspay/hyperswitch-web/releases/tag/v0.109.2) | [v0.6.4](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.4) |  | [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1) |
| v1.6 |  |  |  |  |  |  |  |
| v1.5 | 2024-08-22 | [v1.111.0](https://github.com/juspay/hyperswitch/releases/tag/v1.111.0) |  |  |  |  |  |
| v1.4 | 2024-08-02 | [v1.110.0](https://github.com/juspay/hyperswitch/releases/tag/v1.110.0) |  |  |  |  |  |
| v1.3 | 2024-07-05 | [v1.109.0](https://github.com/juspay/hyperswitch/releases/tag/v1.109.0) |  |  |  |  |  |
| v1.2 | 2024-05-03 | [v1.108.0](https://github.com/juspay/hyperswitch/releases/tag/v1.108.0) |  |  |  |  |  |
| v1.1 | 2024-03-12 | [v1.107.0](https://github.com/juspay/hyperswitch/releases/tag/v1.107.0) |  |  |  |  |  |
| v1.0 | 2024-01-11 | [v1.105.1](https://github.com/juspay/hyperswitch/releases/tag/v1.105.1) |  |  |  |  |  |

## Release notes

Starting with the format below, each suite release documents infrastructure changes (new cloud support, module additions, breaking Terragrunt/module changes, migration notes). Historical entries are being backfilled from git history; entries without infrastructure notes indicate that only upstream compatibility was recorded at the time.

## Hyperswitch Suite v1.21

Compatible with [Hyperswitch App Server v1.126.0](https://github.com/juspay/hyperswitch/releases/tag/v1.126.0) (2026-08-18).
Component matrix: Control Center [v1.38.7](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.7), Web Client [v0.133.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.133.0), Card Vault [v0.9.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.9.0), Encryption Service [v0.1.14](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.14), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

- **GCP catalog units**: added 19 tag-pinned Terragrunt units under `terraform/gcp/catalog/units/` covering networking, data stores, proxies, GKE and application workloads (#311).
- **GCP dev live layer**: added `terraform/gcp/live/dev/asia-south1/` as the hand-written Terragrunt reference deployment for asia-south1 (#312).
- **AWS live layer to Terragrunt**: converted `terraform/aws/live/dev/eu-central-1/` from plain Terraform to Terragrunt equivalents (#313).
- **AWS module hardening**: added mutual-TLS ALB listener support, SSM session-manager logging to proxy roles, separate mTLS listener for Envoy, ALB deletion protection, and fixed target-group `ResourceInUse` errors during canary rollback.
- **Observability**: included AWS region in Loki and Vector S3 bucket names; added SQS cross-region read support for Vector; added default names for Grafana database resources.

## Hyperswitch Suite v1.20

Compatible with [Hyperswitch App Server v1.125.0](https://github.com/juspay/hyperswitch/releases/tag/v1.125.0) (2026-07-09).
Component matrix: Control Center [v1.38.6](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.6), Web Client [v0.132.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.132.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.13](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.13), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

- **AWS networking**: `vpc-network` now supports custom PrivateLink interface endpoints (#263).
- **AWS configuration refactor**: replaced config source path with explicit config files map (#268).

## Hyperswitch Suite v1.19

Compatible with [Hyperswitch App Server v1.124.0](https://github.com/juspay/hyperswitch/releases/tag/v1.124.0) (2026-06-29).
Component matrix: Control Center [v1.38.5](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.5), Web Client [v0.132.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.132.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.18

Compatible with [Hyperswitch App Server v1.123.1](https://github.com/juspay/hyperswitch/releases/tag/v1.123.1) (2026-05-19).
Component matrix: Control Center [v1.38.4](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.4), Web Client [v0.131.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.131.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.17

Compatible with [Hyperswitch App Server v1.123.0](https://github.com/juspay/hyperswitch/releases/tag/v1.123.0) (2026-04-13).
Component matrix: Control Center [v1.38.3](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.3), Web Client [v0.130.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.130.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.16

Compatible with [Hyperswitch App Server v1.122.0](https://github.com/juspay/hyperswitch/releases/tag/v1.122.0) (2026-3-24).
Component matrix: Control Center [v1.38.2](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.2), Web Client [v0.129.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.129.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.15

Compatible with [Hyperswitch App Server v1.121.0](https://github.com/juspay/hyperswitch/releases/tag/v1.121.0) (2026-2-24).
Component matrix: Control Center [v1.38.2](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.38.2), Web Client [v0.129.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.129.0), Card Vault [v0.7.0](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.7.0), Encryption Service [v0.1.12](https://github.com/juspay/hyperswitch-encryption-service/releases/tag/v0.1.12), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.14

Compatible with [Hyperswitch App Server v1.120.0](https://github.com/juspay/hyperswitch/releases/tag/v1.120.0) (2025-11-27).
Component matrix: Control Center [v1.37.8](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.8), Web Client [v0.127.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.127.0), Card Vault [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.13

Compatible with [Hyperswitch App Server v1.119.0](https://github.com/juspay/hyperswitch/releases/tag/v1.119.0) (2025-11-04).
Component matrix: Control Center [v1.37.7](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.7), Web Client [v0.127.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.127.0), Card Vault [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.12

Compatible with [Hyperswitch App Server v1.118.0](https://github.com/juspay/hyperswitch/releases/tag/v1.118.0) (2025-10-14).
Component matrix: Control Center [v1.37.5](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.5), Web Client [v0.126.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.126.0), Card Vault [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.11

Compatible with [Hyperswitch App Server v1.117.0](https://github.com/juspay/hyperswitch/releases/tag/v1.117.0) (2025-09-11).
Component matrix: Control Center [v1.37.4](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.4), Web Client [v0.126.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.126.0), Card Vault [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.10

Compatible with [Hyperswitch App Server v1.116.0](https://github.com/juspay/hyperswitch/releases/tag/v1.116.0) (2025-08-05).
Component matrix: Control Center [v1.37.3](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.3), Web Client [v0.125.0](https://github.com/juspay/hyperswitch-web/releases/tag/v0.125.0), Card Vault [v0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.9

Compatible with [Hyperswitch App Server v1.115.0](https://github.com/juspay/hyperswitch/releases/tag/v1.115.0) (2025-07-02).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.8

Compatible with [Hyperswitch App Server v1.114.0](https://github.com/juspay/hyperswitch/releases/tag/v1.114.0) (2025-04-09).
Component matrix: Control Center [v1.37.1](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.37.1), Web Client [v0.121.2](https://github.com/juspay/hyperswitch-web/releases/tag/v0.121.2), Card Vault [v 0.6.5](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.5), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.7

Compatible with [Hyperswitch App Server v1.113.0](https://github.com/juspay/hyperswitch/releases/tag/v1.113.0) (2025-03-04).
Component matrix: Control Center [v1.36.1](https://github.com/juspay/hyperswitch-control-center/releases/tag/v1.36.1), Web Client [v0.109.2](https://github.com/juspay/hyperswitch-web/releases/tag/v0.109.2), Card Vault [v0.6.4](https://github.com/juspay/hyperswitch-card-vault/releases/tag/v0.6.4), WooCommerce Plugin [v1.6.1](https://github.com/juspay/hyperswitch-woocommerce-plugin/releases/tag/v1.6.1).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.6


### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.5

Compatible with [Hyperswitch App Server v1.111.0](https://github.com/juspay/hyperswitch/releases/tag/v1.111.0) (2024-08-22).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.4

Compatible with [Hyperswitch App Server v1.110.0](https://github.com/juspay/hyperswitch/releases/tag/v1.110.0) (2024-08-02).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.3

Compatible with [Hyperswitch App Server v1.109.0](https://github.com/juspay/hyperswitch/releases/tag/v1.109.0) (2024-07-05).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.2

Compatible with [Hyperswitch App Server v1.108.0](https://github.com/juspay/hyperswitch/releases/tag/v1.108.0) (2024-05-03).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.1

Compatible with [Hyperswitch App Server v1.107.0](https://github.com/juspay/hyperswitch/releases/tag/v1.107.0) (2024-03-12).

### Infrastructure changes

_No infrastructure changes recorded for this release._

## Hyperswitch Suite v1.0

Compatible with [Hyperswitch App Server v1.105.1](https://github.com/juspay/hyperswitch/releases/tag/v1.105.1) (2024-01-11).

### Infrastructure changes

_No infrastructure changes recorded for this release._

