# hyperswitch (OCI)

The OCI port of `terraform/aws/modules/application-resources/hyperswitch`.

Check sheet: `docs/multi-cloud-parity/oci/modules/hyperswitch.md` (hyperswitch-infra).
Identity model: `docs/multi-cloud-parity/oci/identity-model.md`.

## Four surprises, stated up front

1. **There is no `role_arn`, and no policy object.** OCI has no role, no trust
   policy, no assume call and no service-account annotation. This module emits
   `policy_statements` - a list of strings - which the caller concatenates into
   the ONE shared, environment-scoped `oci_identity_policy` owned by the
   `oke-workload-identity` unit. Creating a policy object per app is
   unbuildable: `name` is tenancy-unique and non-updatable, and 12 apps x 11
   live roots is 132 objects against a hard limit of 100.

2. **Cross-region KMS replication requires a virtual private vault.**
   `oci_kms_vault_replication` "only supports virtual private vault", the
   dedicated-HSM tier, and `vault_type` is not updatable in place. Setting
   `kms.create_replica = true` therefore forces `VIRTUAL_PRIVATE` on the vault -
   a standing cost - and that choice must be made before the first apply, per
   environment. One replica region only; there is no path to a third.

3. **Email Delivery's identity story is unresolved.** The workload-identity path
   is built as primary and unconditional (`use email-family`). Whether the HTTPS
   `SubmitEmail` endpoint actually honours a workload principal is check sheet
   section 9 Q1 - Oracle names "API key of an Identity user, instance principal,
   or resource principal" and neither includes nor excludes workload identity.
   The fallback is an SMTP credential, which is a long-lived user-bound static
   credential and an accepted regression. It is opt-in only, provisioned out of
   band, referenced by Vault-secret OCID, and it flips
   `email_uses_static_credential_fallback` so it cannot be taken quietly. This
   module never handles a credential value.

4. **`force_destroy` does not exist.** `oci_objectstorage_bucket` has no such
   argument, and a non-empty bucket cannot be deleted by the resource. Empty it
   first: `oci os object bulk-delete --bucket-name <name> --namespace <ns>`.

## What is deliberately not here

| AWS feature | Why it is absent |
|---|---|
| `assume_role` (cross-account STS) | Verdict NONE. OCI has no role object and no assume operation. Use `extra_statements` to name a second principal directly. |
| SES cross-account role hop | Not portable and not needed - the domain is verified in this tenancy. |
| `lambda:*` + account-wide Lambda list/create actions | Narrowed to `use functions-family` (invoke). Check sheet section 4.3; confirm with the report-pipeline owner before cutover. |
| `key_administrators` / `key_users` / `aliases` | `oci_kms_key` has no key-policy argument. Key access is granted by statement. |
| `additional_iam_policies` (map of JSON) | Collapsed into `extra_statements` (list of strings). |

## Statement budget

7 statements per (cluster x service account) with every feature on; 6 when
`functions.enabled` is false. Narrowing `secrets.secret_ids` costs 2 statements
per secret instead of 2 total - the shared policy object caps at 50.
