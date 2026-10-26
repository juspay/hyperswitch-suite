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

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password='<strong password>'
```

Database bootstrap (once, via a bastion or `kubectl run psql`): create the
`hyperswitch` role/database on the Aurora cluster (writer endpoint is in the
`database` unit outputs). Superposition ships inside the hyperswitch stack
chart and bootstraps its own schema.

## 4. Bootstrap ArgoCD

```bash
./install-argocd.sh
```

This installs the ALB controller, ArgoCD (with the tfstate helm plugin, see
below), and the root app-of-apps. If the repo is private, add repo credentials
when prompted by the script's final message.

### The tfstate helm plugin — how it works

The applications in `argocd/apps/**` reference infrastructure endpoints
(database writer/reader, redis endpoint, EKS cluster name) **without hardcoding
them**. Two pieces make that work:

1. **Helm parameters named `$tfstate.<name>`** on each application, e.g.

   ```yaml
   parameters:
     - name: $tfstate.rds
       value: 's3://__STATE_BUCKET__/__ENVIRONMENT__/__AWS_REGION__/database/terraform.tfstate'
   ```

   Each one registers a terraform state file under an alias (`rds`, `redis`,
   `eks`).

2. **`$<alias.output>$` tokens inside values files**, e.g. in
   `infra-configurations/hyperswitch-stack/values.yaml`:

   ```yaml
   externalPostgresql:
     primary:
       host: $<rds.endpoint>$
   ```

   At render time the plugin downloads the state file from S3, reads its
   terraform **outputs**, and substitutes `$<rds.endpoint>$` with the actual
   Aurora endpoint. Any output of the referenced unit can be used this way.

This is why the terragrunt unit paths must not be renamed: the S3 keys follow
`<env>/<region>/<unit-path>/terraform.tfstate`.

### How the plugin is installed

You don't install it by hand — it is baked into the ArgoCD deployment by
`infra-configurations/argocd/values.yaml`:

- an **initContainer** on the repo-server pod (image
  `__TFSTATE_PLUGIN_IMAGE__`) copies a plugin-wrapped `helm` binary and the
  downloader plugin into a shared volume;
- a **volumeMount** overlays `/usr/local/sbin/helm` in the repo-server with
  that wrapped binary, so every chart render ArgoCD performs goes through the
  plugin.

So the plugin is active as soon as `install-argocd.sh` installs the argo-cd
chart. To verify:

```bash
kubectl -n argocd get pod -l app.kubernetes.io/name=argocd-repo-server \
  -o jsonpath='{.items[0].spec.initContainers[*].name}'   # -> helm-terraform-states
```

**Credentials:** the plugin authenticates to S3 with the repo-server pod's AWS
identity — by default the EKS node role, which the `eks-01` unit already
grants `s3:GetObject`/`s3:ListBucket` on `__STATE_BUCKET__`. No keys to
configure. (If you later move the repo-server to IRSA, grant the same bucket
read to that role.)

**Image note:** `__TFSTATE_PLUGIN_IMAGE__` must be pullable from the cluster.
If you mirror it into your own registry, update the image in
`infra-configurations/argocd/values.yaml` (or rerun the generator with the new
value) and re-sync the `argocd` application.

## 5. Sync applications (in order)

In the ArgoCD UI (or `argocd app sync ...`):

1. `istio-base` then `istiod` — service mesh (upstream istio charts)
2. `victoria-metrics`, `loki`, `vector`, `grafana` — observability
3. `hyperswitch-<name>` — the stack (includes superposition); its `initDB` job
   runs diesel migrations against the Aurora endpoint resolved from terraform
   state.

## 6. Point DNS

Point your domains at the ALBs created by the ingresses (`kubectl get ingress -A`).

## Adding a second region later

Add another element to each ApplicationSet's list generator in
`argocd/apps/**` (new `server`, `s3Bucket`, `region`), render a second live
stack file, and register the new cluster in ArgoCD.
