# locker (OCI)

OCI equivalent of `terraform/aws/modules/composition/locker` (self-managed card-vault instances behind an internal
ALB, with an optional embedded RDS database). Same pattern as `../cassandra`: compute-instance registry module +
plain `oci` NSG/IAM/LB resources, plus a nested call to `../database` mirroring how the AWS `locker` module sources
the sibling `database` composition module when `create_locker_database = true`.

## IAM mapping

| AWS managed policy | OCI policy statement |
|---|---|
| `AmazonEC2ContainerRegistryReadOnly` | `to read repos in compartment ...` (OCIR) |
| `AmazonS3FullAccess` | `to manage objects in compartment ...` (Object Storage) |
| `CloudWatchAgentServerPolicy` | `to use metrics in compartment ...` + `to use log-content in compartment ...` |
| Custom KMS policy | `to use keys ... where target.key.id = ...` (OCI Vault) |

Fixed AWS-managed-policy grants like `AmazonS3FullAccess`/`AmazonEC2ContainerRegistryReadOnly` are broader than
necessary; consider narrowing the OCI policy statements above (e.g. scope Object Storage access to a specific
bucket) before using this in production, same caveat that applies to the AWS module.
