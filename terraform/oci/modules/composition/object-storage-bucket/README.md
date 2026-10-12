# composition/object-storage-bucket

A generic OCI Object Storage bucket. One bucket, an optional lifecycle policy,
and optional Terraform-managed objects. Nothing else.

## Why this exists separately from the state bucket

The Terraform-state bucket is deliberately not generic: `versioning =
"Enabled"` and `access_type = "NoPublicAccess"` are posture literals, the name
is derived from the state bucket name, and it creates an `oci_identity_policy`
for state access. Making those two literals into inputs would remove the
guarantee that module exists to provide.

## Position in the port

| | |
|---|---|
| AWS counterpart | `aws_s3_bucket` used ad hoc by app modules; there is no shared AWS bucket module |
| GCP counterpart | `tfr:///terraform-google-modules/cloud-storage//modules/simple_bucket`, sourced directly by the (now deleted) `apps/hyperswitch-sdk-assets` GCP unit |
| Strategy | `DIRECT-RESOURCE` - see `docs/multi-cloud-parity/oci/provider-facts.md`: OCI has essentially one well-maintained registry module, so a registry module is the exception here, not the default |

## The three facts a caller needs

1. **`access_type` is the entire anonymous-access surface.** There is no
   `oci_objectstorage_bucket_policy` resource and no S3-style public-access
   block. `ObjectReadWithoutList` permits `GetObject`/`HeadObject` only;
   `ObjectRead` additionally permits `ListObjects` and is strictly wider.
2. **The native endpoint is browser-valid HTTPS with zero extra
   infrastructure.** `base_url` is
   `https://objectstorage.<region>.oraclecloud.com/n/<ns>/b/<bucket>/o`, served
   with a DigiCert-issued certificate, HSTS, and
   `access-control-allow-origin: *` (verified live in `ap-mumbai-1`,
   2026-09-05). No custom domain, no certificate resource, no CDN needed to get
   TLS.
3. **That URL is a path prefix, not an origin root.** Any consumer that emits
   absolute-from-root asset URLs (`/web/x/y.js`) will resolve them against
   `https://objectstorage.<region>.oraclecloud.com/` and miss the bucket. This
   is the single real constraint on serving a webpack bundle from here.

## Not implemented, deliberately

- No IAM policy. Grants to named principals belong in the one per-environment
  `oci_identity_policy` object owned by the `oke-workload-identity` unit
  (100-policy-objects-per-tenancy limit).
- No `force_destroy`. The argument does not exist and the API refuses to delete
  a non-empty bucket. Run `oci os object bulk-delete` first.
- No retention rules. Mutually exclusive with versioning in both directions
  (build-log C2).
- No CORS. There is no CORS argument on the resource, and the endpoint already
  returns a wildcard `access-control-allow-origin`.
