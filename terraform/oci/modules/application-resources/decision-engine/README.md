# decision-engine (OCI)

A hybrid of its two siblings: `superposition`'s generic role-factory surface
plus two of `hyperswitch`'s hardcoded feature-flagged policies (a dedicated
bucket, and SES).

## Three things to know

1. **No `role_arn`, no policy object.** This module emits `policy_statements`
   for the ONE shared, environment-scoped policy owned by
   `oke-workload-identity`. Three statements per cluster per service account:
   `use keys` on hyperswitch's key, `manage objects` on this bucket,
   `use email-family`.

2. **The email identity is shared by default.** This module and `hyperswitch`
   send through the same SES role today. `email.create` therefore defaults to
   **false** here and to true there: point `email.use_existing_domain_id` at
   hyperswitch's output. Owning a second verified domain for the same logical
   sender is duplicated DNS verification for no isolation benefit. The create
   path is written and validated, so flipping it is a `values` change.

3. **There is no CDN.** `cloudfront_distribution_arns` and its Origin-Access-
   Control bucket policy are dropped. OCI's only CDN-adjacent offering is a
   third-party Cloudflare peering arrangement with no Terraform resource behind
   it. Unused on AWS today, so zero blast radius — but a future CDN in front of
   this bucket is a new architecture decision, not a parameter here.

## Other absences

- No `force_destroy` — a non-empty bucket cannot be deleted by the resource;
  run `oci os object bulk-delete` first.
- No `aws_managed_policy_names` — there is no attachable canned-policy library.
- `customer_managed_policy_arns` folded into `extra_statements`.
- No STS/role plumbing (`assume_role_principals`, `role_path`,
  `max_session_duration`) — there is no role.
- No SES cross-account role hop — no cross-tenancy borrowed-sender pattern
  exists.
- The region suffix in the bucket name is dropped; OCI names are unique within
  the tenancy's namespace, not globally. Override `bucket.bucket_name` to keep
  it.

## Known drift, unresolved

The pinned AWS catalog unit passes `secrets_manager_secret_arns`, a variable
the module on `main` does not declare — silently ignored by Terraform. Either
the pinned version differs from `main` or it is dead input. This port followed
`main` and has no secrets feature.