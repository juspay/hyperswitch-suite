# infraswitch-gcp-federation

Lets an AWS-only CI/CD apply worker (e.g. [infra-switch](https://github.com/juspay/argo-tg),
Atlantis, or anything else that runs `terraform`/`terragrunt` from a pod or
instance authenticated as an AWS IAM role) run against GCP with no static
key: a Workload Identity Pool trusts that one AWS role, and that federated
identity is granted GCP project roles directly - no service account, no
impersonation.

## Usage

```hcl
module "infraswitch_gcp_federation" {
  source = "../../modules/application-resources/infraswitch-gcp-federation"

  project_id     = "your-gcp-project"
  aws_account_id = "111111111111"
  aws_role_name  = "your-ci-apply-role"
}
```

## One-time manual bootstrap (not Terraform)

After applying, generate the credential-config file your CI/CD worker mounts:

```bash
gcloud iam workload-identity-pools create-cred-config \
  "$(terraform output -raw workload_identity_pool_provider_name)" \
  --aws \
  --output-file=credential-config.json
```

No `--service-account` flag - the credential resolves to the federated
identity itself, which already holds the project roles granted above. Point
`GOOGLE_APPLICATION_CREDENTIALS` at this file from your worker's pods/
instances and standard GCP ADC resolution picks it up automatically.

GCP `provider "google"` blocks in your own terraform need no identity
override at all: humans keep applying with their own GCP permissions
exactly as before this module existed; your CI/CD worker authenticates as
the AWS role, separately, whenever it runs.
