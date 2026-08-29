# Self-hosted Hyperswitch — __MERCHANT_NAME__ (__ENVIRONMENT__, __AWS_REGION__)

Rendered by `scripts/self-host/generate.sh` from `hyperswitch-bootstrap.conf`.
To change any value: edit the conf file and rerun the generator with `--force`.

## What was generated

| Path | Purpose |
|---|---|
| `terraform/aws/live/__ENVIRONMENT__/terragrunt.stack.hcl` | Terragrunt stack (database, elasticache, efs, eks, eks-resources, security-rules) |
| `argocd/` | ArgoCD app-of-apps bundle (values files for the argocd-apps chart) |
| `infra-configurations/`, `deployment-configs/` | Per-application Helm values |
| `install-argocd.sh` | Cluster bootstrap script |

## Prerequisites

- Terraform state bucket `__STATE_BUCKET__` exists (versioned + encrypted).
- VPC `__VPC_ID__` subnets are tagged for load balancers:
  public subnets `kubernetes.io/role/elb=1`, private `kubernetes.io/role/internal-elb=1`.
- DNS for `__ROUTER_DOMAIN__`, `__SDK_DOMAIN__`, `__CONTROL_CENTER_DOMAIN__` under
  your control; ACM cert `__ACM_CERT_ARN__` covers them.
- Tools: awscli, terragrunt (>= 0.80), opentofu/terraform, kubectl, helm, yq.
- This repo pushed to `__MERCHANT_REPO_URL__` (ArgoCD pulls values from it).

## 1. Provision infrastructure

```bash
cd terraform/aws/live/__ENVIRONMENT__
terragrunt stack generate          # renders the unit tree into __AWS_REGION__/
git add . && git commit -m 'render terragrunt stack'
cd __AWS_REGION__
terragrunt run-all apply           # database/elasticache/efs -> eks-01 -> eks-resources -> security-rules
```

For a cautious first run, apply unit-by-unit in that order instead of `run-all`.

## 2. Connect kubectl

```bash
aws eks update-kubeconfig --region __AWS_REGION__ --name <cluster name from eks-01 output>
```

## 3. Create application secrets

Secrets are never stored in this repo. Create them before syncing apps:

```bash
kubectl create namespace hyperswitch --dry-run=client -o yaml | kubectl apply -f -
kubectl -n hyperswitch create secret generic hyperswitch-db-credentials \
  --from-literal=password='<database password for the hyperswitch user>'

kubectl create namespace superposition --dry-run=client -o yaml | kubectl apply -f -
kubectl -n superposition create secret generic hyperswitch-db-credentials \
  --from-literal=password='<same database password>'

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password='<strong password>'
```

Database bootstrap (once, via a bastion or `kubectl run psql`): create the
`hyperswitch` role/database on the Aurora cluster (writer endpoint is in the
`database` unit outputs), and a `superposition` database on the same cluster.

## 4. Bootstrap ArgoCD

```bash
./install-argocd.sh
```

This installs the ALB controller, ArgoCD (with the tfstate helm plugin image
`__TFSTATE_PLUGIN_IMAGE__`), and the root app-of-apps. If the repo is private,
add repo credentials when prompted by the script's final message.

The tfstate plugin reads `s3://__STATE_BUCKET__/...` using the node role — the
eks-01 unit already grants it read access to the state bucket.

## 5. Sync applications (in order)

In the ArgoCD UI (or `argocd app sync ...`):

1. `istio` — service mesh + gateway
2. `victoria-metrics`, `loki`, `vector`, `grafana` — observability
3. `superposition` — config service (runs its schema bootstrap)
4. `hyperswitch-<name>` — the stack; its `initDB` job runs diesel migrations
   against the Aurora endpoint resolved from terraform state.

## 6. Point DNS

Point your domains at the ALBs created by the ingresses (`kubectl get ingress -A`).

## Adding a second region later

Add another element to each ApplicationSet's list generator in
`argocd/apps/**` (new `server`, `s3Bucket`, `region`), render a second live
stack file, and register the new cluster in ArgoCD.
