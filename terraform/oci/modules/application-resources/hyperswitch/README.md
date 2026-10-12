# hyperswitch (OCI)

Application resources (KMS, object storage, email, secrets grants, policy
statements) for the Hyperswitch workload on OCI.

## Four things to know

1. **There is no `role_arn`, and no policy object.** OCI has no role, trust
   policy, assume call or service-account annotation. The module emits
   `policy_statements` — a list of strings — which the caller concatenates into
   the ONE shared, environment-scoped `oci_identity_policy` owned by the
   `oke-workload-identity` unit. A policy object per app is unbuildable: `name`
   is tenancy-unique and non-updatable, against a hard limit of 100.

2. **Cross-region KMS replication requires a virtual private vault.**
   `oci_kms_vault_replication` only supports the `VIRTUAL_PRIVATE` (dedicated
   HSM) tier, and `vault_type` is not updatable in place. Setting
   `kms.create_replica = true` therefore forces `VIRTUAL_PRIVATE` — a standing
   cost — and the choice must be made before first apply. One replica region
   only.

3. **Email Delivery's identity story is unresolved.** Workload identity is the
   primary path (`use email-family`); whether the HTTPS `SubmitEmail` endpoint
   honours a workload principal is unconfirmed. The fallback is a long-lived
   SMTP credential, opt-in only, provisioned out of band, referenced by
   Vault-secret OCID, and it flips `email_uses_static_credential_fallback` so it
   cannot be taken quietly. This module never handles a credential value.

4. **`force_destroy` does not exist.** `oci_objectstorage_bucket` has no such
   argument and a non-empty bucket cannot be deleted by the resource. Empty it
   first: `oci os object bulk-delete --bucket-name <name> --namespace <ns>`.

## Deliberately not here

- No `assume_role` / STS — OCI has no role object. Use `extra_statements` to
  name a second principal directly.
- Lambda actions narrowed to `use functions-family` (invoke).
- No key-policy argument on `oci_kms_key` — key access is granted by statement.
- `additional_iam_policies` (map of JSON) collapsed into `extra_statements`
  (list of strings).

## Statement budget

7 statements per (cluster x service account) with every feature on; 6 when
`functions.enabled` is false. Narrowing `secrets.secret_ids` costs 2 statements
per secret instead of 2 total — the shared policy object caps at 50.