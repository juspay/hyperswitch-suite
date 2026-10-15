# vault (OCI)

One dedicated `DEFAULT` OCI Vault and one symmetric AES-256 master key, for the
ESO (External Secrets Operator) secret-delivery path. Encryption-service,
card-vault, and superposition's DB passwords live as OCI secrets under this
Vault and reach the cluster through ESO.

## Boundary (what this module does NOT do)

Kept deliberately narrow, matching how the identity is structured on OCI:

- **No `oci_identity_policy`.** On OCI a policy object IS the grant; the platform
  runs one shared policy object per environment, owned by `oke-workload-identity`.
  The ESO module contributes its grants there.
- **No dynamic group.** OKE workload identities cannot use dynamic groups.
- **No secrets.** Secret-bundle creation is an out-of-band, interactive step so
  secret content never enters Terraform state or git.
- **No workload-identity grant in this module.** The consuming ESO module owns
  `secret_store_config` and the statement renderer.

If you find this module drifting toward any of those, that is the bug - the
single-vault ownership boundary is the point of the module.

## Resources

- `oci_kms_vault` (type `DEFAULT`, dev compartment), destruction-guarded.
- `oci_kms_key` (AES-256, software protection), destruction-guarded, from the
  Vault's own management endpoint.

## Outputs

`vault_id`, `compartment_id`, `key_id`, `region`, `management_endpoint`,
`crypto_endpoint`.

`vault_id` flows into ESO's `SecretStore` (`spec.provider.oracle.vault`);
`key_id` encrypts the secret bundles at creation time.

## DR / VPC note

`vault_type` is hard-coded to `DEFAULT`. A single-region sandbox takes the
default; replication (DR) would require `VIRTUAL_PRIVATE`, which forces a
Vault replacement and is a deliberate caller-side decision, not a guess this
module makes.

## Test

`terraform -chdir=terraform/oci/modules/application-resources/vault test`
runs the boundary tests (`tests/vault.tftest.hcl`) with a mock provider:
asserts the two-resource shape, correct outputs, invalid-input rejection, and
that no IAM/secret-content resources leak in.