# decision-engine (OCI)

The OCI port of `terraform/aws/modules/application-resources/decision-engine`.

Check sheet: `docs/multi-cloud-parity/oci/modules/decision-engine.md`.

A hybrid of its two siblings: `superposition`'s generic role-factory surface
plus two of `hyperswitch`'s hardcoded feature-flagged policies (a dedicated
bucket, and SES).

## Three things to know

1. **No `role_arn`, no policy object.** This module emits `policy_statements`
   for the ONE shared, environment-scoped policy owned by
   `oke-workload-identity`. Three statements per cluster per service account:
   `use keys` on hyperswitch's key, `manage objects` on this bucket,
   `use email-family`. `identity-model.md` section 1.2 estimated two - it missed
   the KMS grant the real catalog unit has.

2. **The email identity is shared by default.** This module and `hyperswitch`
   send through the same AWS SES role today. `email.create` therefore defaults
   to **false** here and to true there: point `email.use_existing_domain_id` at
   hyperswitch's output. Owning a second verified domain for the same logical
   sender is duplicated DNS verification for no isolation benefit. Oracle gate
   item, not yet consulted; the create path is written and validated so
   flipping it is a `values` change.

3. **There is no CDN.** `cloudfront_distribution_arns` and its Origin-Access-
   Control bucket policy are dropped, verdict NONE. OCI's only CDN-adjacent
   offering is a third-party Cloudflare peering arrangement restricted to North
   America with no Terraform resource behind it. Unused on AWS today, so zero
   blast radius - but a future CDN in front of this bucket is a new architecture
   decision needing its own gate pass, not a parameter here.

## Other absences

| AWS surface | Why |
|---|---|
| `force_destroy` | No such argument; a non-empty bucket cannot be deleted by the resource. `oci os object bulk-delete` first. |
| `aws_managed_policy_names` | Verdict NONE - no attachable canned-policy library. |
| `customer_managed_policy_arns` | Folded into `extra_statements`. |
| `assume_role_principals`, `role_path`, `max_session_duration` | STS/role plumbing; there is no role. |
| SES cross-account role hop | No cross-tenancy borrowed-sender pattern exists. |
| The region suffix in the bucket name | OCI names are unique within the tenancy's namespace, not globally. Override `bucket.bucket_name` to keep it. |

## Known drift, unresolved

The pinned AWS catalog unit (`apps-decision-engine-v0.1.2`) passes
`secrets_manager_secret_arns`, a variable the module on `main` does not declare -
silently ignored by Terraform. Either the pinned version differs from `main` or
it is dead input. This port followed `main` and has no secrets feature. Check
sheet section 9 Q4.
