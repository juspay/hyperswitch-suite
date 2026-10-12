# container-registry

OCI Container Registry (OCIR) repositories, plus an optional compartment-level
IAM policy.

## Repository naming

The pull path is `<region>.ocir.io/<tenancy-namespace>/<repository>:<tag>`.
**Repository names are unique across the whole tenancy namespace, regardless of
compartment**, so environments sharing a tenancy cannot both own
`hyperswitch-router`. Use `repository_name_prefix` (e.g. `"dev/"`) to scope
them.

## How OKE pulls from this registry

Not with IAM. OKE requires a Kubernetes `docker-registry` Secret built from a
long-lived OCI Auth Token, and that token is deliberately **not** created here
(it would land in Terraform state in plaintext). The module emits
`image_pull_secret_docker_server` and `image_pull_username_prefix`; the token
and the Secret belong to cluster bootstrap. Granting a pod's workload identity
`read repos` does **not** enable image pulls — the kubelet does the pulling and
has no workload identity.

## Known gaps

- No image-retention mechanism exists on the `oracle/oci` repository resource;
  out-of-band automation is the only path.
- No push-triggered image scanning; OCI's Vulnerability Scanning Service is
  standalone.
- No customer-managed encryption key on the repository resource.
- `image_tag_mutability` is all-or-nothing (`is_immutable`); split repositories
  rather than relying on exclusion filters.

Each of these is commented at the point of divergence in `main.tf` /
`variables.tf`.