# ecr (OCI) → OCIR (Container Registry)

OCI equivalent of `terraform/aws/modules/composition/ecr`. Uses `oci_artifacts_container_repository`. No verified
registry module exists - raw `oci` provider resource.

## Mapping notes

- ECR's per-repository lifecycle policies and repository policies (`aws_ecr_lifecycle_policy`,
  `aws_ecr_repository_policy`) have no direct per-repository resource equivalent in OCIR — image retention is
  managed tenancy/compartment-wide via **OCI Artifacts retention policies**, and access is controlled via IAM
  policies on the `repos`/`repository` resource type (see the `../locker/README.md` IAM mapping table for an
  example `to read repos in compartment ...` statement), not a resource-attached JSON policy document.
- Authentication for `docker push`/`pull` uses an **OCI Auth Token** (`oci_identity_auth_token`) per user, or
  Instance Principal auth from OKE nodes/workloads — there's no ECR-style `aws ecr get-login-password` single
  command; see the `eks-kubernetes-resources` module's OCIR registry-secret notes.
