# email-delivery (OCI)

One shared OCI Email Delivery domain + approved sender pair, extracted from the
inline `email.tf` that `hyperswitch` and `decision-engine` each carried. One
logical sender is described once and reused by both.

## Boundary (what this module does NOT do)

- **No workload-identity grant.** The consuming module owns its `use
  email-family` statement into the shared `oke-workload-identity` policy object;
  this module only claims the domain and sender objects the grant protects.
- **No SMTP credential creation.** `oci_identity_smtp_credential` is bound to an
  IAM user and is exactly the long-lived static credential the identity model
  rejects. The static fallback is opt-in only, operator-provisioned out of
  band, referenced by Vault-secret OCID, and flips
  `email_uses_static_credential_fallback` so it cannot be taken silently.
- **No policy object.** On OCI a policy IS the grant; the platform runs one
  shared policy object per environment.

## Resources

- `oci_email_email_domain` (count = `email.create`), destruction-guarded ordering
  via the sender's `depends_on`.
- `oci_email_sender` (count = `email.create`), under the verified domain, with a
  `lifecycle.precondition` enforcing the sender address is under `domain_name`.

`use_existing_domain_id` / `use_existing_sender_id` allow a second consumer to
reuse `hyperswitch`'s verified domain rather than verifying a duplicate.

## Outputs

`email_domain_id`, `email_sender_id`, `email_sender_address`,
`email_uses_static_credential_fallback`, `smtp_credential_vault_secret_id`.

`email_domain_id` / `email_sender_id` are what `decision-engine` consumes to
share the sender; `email_uses_static_credential_fallback` surfaces the SMTP
regression in every consumer's plan.