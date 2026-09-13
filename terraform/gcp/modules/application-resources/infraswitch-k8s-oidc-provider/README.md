# infraswitch-k8s-oidc-provider

Adds a generic OIDC provider to an **existing** workload identity pool
(created separately by [infraswitch-gcp-federation](../infraswitch-gcp-federation)),
trusting a Kubernetes cluster's own OIDC issuer — so a pod can authenticate
to GCP using its own ServiceAccount token, with no AWS credential in the
path.

## Usage

```hcl
module "infraswitch_k8s_oidc_provider" {
  source = "../../modules/application-resources/infraswitch-k8s-oidc-provider"

  project_id          = "your-gcp-project"
  eks_cluster_name    = "your-eks-cluster"
  eks_oidc_issuer_url = "https://oidc.eks.<region>.amazonaws.com/id/<cluster-id>"

  k8s_namespace       = "infra-switch"
  k8s_service_account = "infra-switch-sa"
}
```

`eks_oidc_issuer_url` comes from:

```bash
aws eks describe-cluster --name your-eks-cluster --region <region> \
  --query "cluster.identity.oidc.issuer" --output text
```

`workload_identity_pool_id` defaults to `"infraswitch-aws-pool"` — the pool
`infraswitch-gcp-federation` creates. Override it only if that module's own
`workload_identity_pool_id` was customized.

## One-time manual step (not Terraform): the pod's credential config

`credential_source.file` is a plain local path, hand-written once as a
Kubernetes ConfigMap/Secret value:

```json
{
  "universe_domain": "googleapis.com",
  "type": "external_account",
  "audience": "<see below>",
  "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
  "token_url": "https://sts.googleapis.com/v1/token",
  "credential_source": {
    "file": "/var/run/secrets/gcp-k8s-token/token"
  }
}
```

The pod needs a dedicated projected ServiceAccount token volume whose
`audience` matches this config's `audience` field exactly:

```yaml
volumes:
  - name: infraswitch-k8s-token
    projected:
      sources:
        - serviceAccountToken:
            path: token
            audience: "<same audience string as above>"
            expirationSeconds: 3600
```

`audience` defaults to this provider's own canonical resource name:

```
//iam.googleapis.com/projects/<GCP_PROJECT_NUMBER>/locations/global/workloadIdentityPools/infraswitch-aws-pool/providers/infraswitch-k8s-provider
```

`GCP_PROJECT_NUMBER` is the project's numeric number, not its string ID —
`gcloud projects describe <project_id> --format="value(projectNumber)"`.

Point `GOOGLE_APPLICATION_CREDENTIALS` at the credential config file.
`provider "google"` blocks in your own terraform need no identity
override: the CI/CD worker authenticates as the federated identity
separately, whenever it runs.
