# atlantis-gcp-federation

Lets infra-switch (running only in AWS, authenticated via IRSA as the
`atlantis-role` IAM role) run `terragrunt apply` against GCP with no static
key: a Workload Identity Pool trusts that one AWS role, and that federated
identity is granted GCP project roles directly - no service account, no
impersonation.

## Usage

```hcl
module "atlantis_gcp_federation" {
  source = "../../modules/application-resources/atlantis-gcp-federation"

  project_id     = "hyperswitch-dev"
  aws_account_id = "143555788000"
  aws_role_name  = "atlantis-role"
}
```

## One-time manual bootstrap (not Terraform)

After applying, generate the credential-config file infra-switch mounts:

```bash
gcloud iam workload-identity-pools create-cred-config \
  "$(terragrunt output -raw workload_identity_pool_provider_name)" \
  --aws \
  --output-file=credential-config.json
```

No `--service-account` flag - the credential resolves to the federated
identity itself, which already holds the project roles granted above.
GCP live-tree `root.hcl` files need no provider-level identity override:
humans keep applying with their own GCP permissions exactly as before this
module existed; infra-switch authenticates as the AWS role, separately.
