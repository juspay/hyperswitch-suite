# Atlantis — Production Helm Values

[Atlantis](https://www.runatlantis.io/) is a self-hosted application that automates
Terraform workflows via pull-request comments. It listens for webhook events from
your VCS provider, runs `terraform plan` automatically on every PR, and lets
authorized users merge infrastructure changes by commenting `atlantis apply`.

This directory contains a documented [`prod-values.yaml`](./prod-values.yaml) file
for deploying Atlantis on Kubernetes using the official
[Helm chart](https://github.com/runatlantis/helm-charts).

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [File structure](#file-structure)
3. [Key configuration sections](#key-configuration-sections)
   - [Server identity & URL](#1-server-identity--url)
   - [Organisation allowlist](#2-organisation-allowlist)
   - [Logging](#3-logging)
   - [VCS integration](#4-vcs-integration)
   - [Credential secrets](#5-credential-secrets)
   - [Repository configuration](#6-repository-configuration)
   - [Persistence](#7-persistence)
   - [Service & Ingress](#8-service--ingress)
   - [Resources & replicas](#9-resources--replicas)
   - [Service account (IRSA)](#10-service-account-irsa)
   - [Security context](#11-security-context)
   - [Environment variables](#12-environment-variables)
4. [Quick-start deployment](#quick-start-deployment)
5. [Webhook setup](#webhook-setup)
6. [Security recommendations](#security-recommendations)

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Kubernetes | 1.24+ |
| Helm | 3.x |
| Terraform | 1.0+ (inside the Atlantis pod) |
| AWS CLI | Any recent version (for IRSA setup) |

---

## File structure

```
terraform/aws/atlantis/
└── prod-values.yaml   # Helm values for the production Atlantis deployment
```

---

## Key configuration sections

### 1. Server identity & URL

```yaml
fullnameOverride: ""   # Override the full Helm release name
nameOverride: ""       # Override only the chart-name portion
atlantisUrl: "https://atlantis.example.com"
```

`atlantisUrl` is the **public HTTPS URL** at which Atlantis is reachable. Your VCS
provider sends webhook payloads to `<atlantisUrl>/events`. Links in pull-request
comments also point to this URL, so it must be externally reachable.

---

### 2. Organisation allowlist

```yaml
orgAllowlist: "github.com/your-org/*"
```

A comma-separated list of patterns for repositories that are permitted to interact
with this Atlantis instance. Wildcards (`*`) are supported.

| Pattern | Effect |
|---------|--------|
| `github.com/myorg/*` | All repos under `myorg` |
| `github.com/myorg/myrepo` | Only `myrepo` |
| `*` | **Danger** — every repo on the VCS host |

Always restrict this to the minimum set of repositories in production.

---

### 3. Logging

```yaml
logLevel: "info"
```

| Level | Use case |
|-------|----------|
| `debug` | Troubleshooting — logs every webhook payload and Terraform command |
| `info` | Production default — operational events |
| `warn` | Only warnings and errors |
| `error` | Critical errors only |

---

### 4. VCS integration

Atlantis supports **GitHub**, **GitLab**, **Bitbucket**, and **Gitea**. Configure
exactly **one** provider by filling in its section and commenting out the others.

#### GitHub

```yaml
github:
  user: "atlantis-bot"   # Bot account username
  token: ""              # PAT with repo + admin:repo_hook scopes
  secret: ""             # Webhook secret (must match what you set in GitHub)
  # hostname: ""         # Set for GitHub Enterprise
```

#### GitLab

```yaml
gitlab:
  user: "atlantis-bot"
  token: ""              # PAT with api scope
  secret: ""             # Webhook secret token
  # hostname: ""         # Set for self-hosted GitLab
```

#### Bitbucket Cloud

```yaml
bitbucket:
  user: "atlantis-bot"
  token: ""              # Bitbucket app password
  # Note: Bitbucket Cloud does not support webhook secrets
```

#### Gitea

```yaml
gitea:
  user: "atlantis-bot"
  token: ""
  secret: ""
  baseURL: "https://gitea.example.com"
```

> **Never store tokens or secrets as plain text in version control.**
> Use the `environmentSecrets` mechanism described in the next section.

---

### 5. Credential secrets

```yaml
environmentSecrets:
  - name: ATLANTIS_GH_TOKEN
    secretKeyRef:
      name: atlantis-vcs
      key: ATLANTIS_GH_TOKEN
  - name: ATLANTIS_GH_WEBHOOK_SECRET
    secretKeyRef:
      name: atlantis-vcs
      key: ATLANTIS_GH_WEBHOOK_SECRET
```

Create the Kubernetes Secret **before** installing the chart:

```bash
kubectl create secret generic atlantis-vcs \
  --namespace atlantis \
  --from-literal=ATLANTIS_GH_TOKEN="<your-github-pat>" \
  --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="<your-webhook-secret>"
```

Each entry in `environmentSecrets` injects a secret key as an environment variable
into the Atlantis pod. Atlantis maps well-known env-var names like
`ATLANTIS_GH_TOKEN` automatically to the corresponding configuration fields.

---

### 6. Repository configuration

```yaml
repoConfig: |
  ---
  repos:
    - id: /.*/
      allowed_overrides: [workflow]
      allow_custom_workflows: false
```

The inline `repoConfig` is a
[server-side repo config](https://www.runatlantis.io/docs/server-side-repo-config.html)
that controls per-repository policies:

| Field | Purpose |
|-------|---------|
| `id` | Regex or exact repo URL to match |
| `allowed_overrides` | Which `atlantis.yaml` keys repos may override |
| `allow_custom_workflows` | Whether repos can define their own `workflow:` steps |
| `delete_source_branch_on_merge` | Auto-delete the PR branch after apply |

---

### 7. Persistence

```yaml
persistence:
  enabled: true
  storageClass: "gp3"
  size: 5Gi
  accessMode: ReadWriteOnce
```

Atlantis stores plan files and lock state on disk. A **PersistentVolumeClaim** is
required in production so that data survives pod restarts. Without it, in-progress
plans would be lost whenever the pod is rescheduled.

Choose a `storageClass` appropriate for your cluster:

| Environment | Recommended class |
|-------------|------------------|
| AWS EKS | `gp3` (or `gp2`) |
| GKE | `standard-rwo` |
| AKS | `managed-premium` |
| On-prem | Your CSI provisioner |

---

### 8. Service & Ingress

```yaml
service:
  type: ClusterIP
  port: 80
  targetPort: 4141

ingress:
  enabled: true
  ingressClassName: "nginx"
  hosts:
    - host: atlantis.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: atlantis-tls
      hosts:
        - atlantis.example.com
```

- Atlantis listens on port **4141** by default.
- Use `service.type: ClusterIP` behind an Ingress for production; use
  `LoadBalancer` only if you have no Ingress controller.
- TLS is **required** in production — VCS providers will only deliver webhooks to
  HTTPS endpoints with a valid certificate.

---

### 9. Resources & replicas

```yaml
replicaCount: 1

resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
  limits:
    cpu: "1000m"
    memory: "2Gi"
```

> **Important:** Atlantis uses file-system locking by default and does **not**
> support multiple replicas. Keep `replicaCount: 1` unless you configure an
> external lock store.

Memory consumption scales with the number of concurrent plan/apply operations and
the size of your Terraform state. Start with `2Gi` and increase if you see OOM
kills during large applies.

---

### 10. Service account (IRSA)

```yaml
serviceAccount:
  create: true
  name: "atlantis"
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::XXXXXXXXXXXX:role/atlantis-role"
```

On EKS, IRSA (IAM Roles for Service Accounts) lets the Atlantis pod assume an IAM
role without long-lived access keys. The role must include all AWS permissions
referenced by your Terraform configurations.

Steps to set up IRSA:

1. Create an OIDC provider for your cluster (if not already done):
   ```bash
   eksctl utils associate-iam-oidc-provider --cluster <cluster-name> --approve
   ```
2. Create an IAM role with a trust policy that allows the `atlantis` service
   account to assume it.
3. Attach the necessary IAM policies to the role.
4. Replace `XXXXXXXXXXXX` with your AWS account ID in the annotation above.

---

### 11. Security context

```yaml
podSecurityContext:
  fsGroup: 1000
  runAsUser: 100
  runAsGroup: 1000
  runAsNonRoot: true
```

Running Atlantis as a non-root user limits the blast radius of any container
escape. The `fsGroup` ensures that volume mounts are writable by the Atlantis
process.

---

### 12. Environment variables

```yaml
environment:
  ATLANTIS_PARALLEL_POOL_SIZE: "3"
  ATLANTIS_DEFAULT_TF_VERSION: "1.7.0"
```

| Variable | Purpose |
|----------|---------|
| `ATLANTIS_PARALLEL_POOL_SIZE` | Maximum number of concurrent plan/apply operations |
| `ATLANTIS_DEFAULT_TF_VERSION` | Default Terraform version when `atlantis.yaml` does not specify one |
| `ATLANTIS_DISABLE_AUTOPLAN` | Set to `"true"` to require explicit `atlantis plan` comments |

For the full list of supported environment variables see the
[Atlantis configuration reference](https://www.runatlantis.io/docs/server-configuration.html).

---

## Quick-start deployment

```bash
# 1. Add the Helm repository
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm repo update

# 2. Create the namespace
kubectl create namespace atlantis

# 3. Create the VCS credentials secret
kubectl create secret generic atlantis-vcs \
  --namespace atlantis \
  --from-literal=ATLANTIS_GH_TOKEN="<github-pat>" \
  --from-literal=ATLANTIS_GH_WEBHOOK_SECRET="<webhook-secret>"

# 4. Create the TLS secret (or let cert-manager manage it)
kubectl create secret tls atlantis-tls \
  --namespace atlantis \
  --cert=tls.crt \
  --key=tls.key

# 5. Install / upgrade Atlantis
helm upgrade --install atlantis runatlantis/atlantis \
  --namespace atlantis \
  --values prod-values.yaml \
  --wait
```

---

## Webhook setup

After Atlantis is running, register the webhook in your VCS:

### GitHub

1. Go to **Settings → Webhooks → Add webhook** in your repository or organisation.
2. Set **Payload URL** to `https://atlantis.example.com/events`.
3. Set **Content type** to `application/json`.
4. Enter the same value you used for `ATLANTIS_GH_WEBHOOK_SECRET`.
5. Select **Let me select individual events** and enable:
   - Pull request reviews
   - Pushes
   - Issue comments
   - Pull requests

### GitLab

1. Go to **Settings → Webhooks** in your project or group.
2. Set **URL** to `https://atlantis.example.com/events`.
3. Set the **Secret token** to your webhook secret.
4. Enable: **Push events**, **Comments**, **Merge request events**.

---

## Security recommendations

| Recommendation | Reason |
|----------------|--------|
| Use `environmentSecrets` for all credentials | Avoid plaintext secrets in Helm values |
| Restrict `orgAllowlist` to specific repos/orgs | Prevent untrusted repos from triggering applies |
| Enable TLS on the Ingress | VCS providers require HTTPS for webhooks |
| Set `allow_custom_workflows: false` | Prevent arbitrary code execution via `atlantis.yaml` |
| Use IRSA instead of static AWS credentials | Eliminates long-lived access keys |
| Set `runAsNonRoot: true` | Reduces container escape impact |
| Pin Terraform versions | Ensures reproducible plan/apply behaviour |
| Enable `podDisruptionBudget` | Prevents accidental downtime during node maintenance |
