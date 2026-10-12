# composition/object-storage-bucket

A generic OCI Object Storage bucket: one bucket, an optional lifecycle policy,
and optional Terraform-managed objects.

## The three facts a caller needs

1. **`access_type` is the entire anonymous-access surface.** There is no bucket
   policy resource and no public-access block. `ObjectReadWithoutList` permits
   `GetObject`/`HeadObject` only; `ObjectRead` additionally permits
   `ListObjects` and is strictly wider.
2. **The native endpoint is browser-valid HTTPS with zero extra infrastructure.**
   `base_url` is
   `https://objectstorage.<region>.oraclecloud.com/n/<ns>/b/<bucket>/o`, served
   with a DigiCert-issued certificate, HSTS, and
   `access-control-allow-origin: *`. No custom domain or CDN is needed for TLS.
3. **That URL is a path prefix, not an origin root.** Consumers that emit
   absolute-from-root asset URLs (`/web/x/y.js`) will resolve them against the
   region root and miss the bucket.

## Not implemented, deliberately

- **No IAM policy.** Grants to named principals belong in the per-environment
  `oci_identity_policy` object owned elsewhere (100-policy-objects-per-tenancy
  limit).
- **No `force_destroy`.** The argument does not exist and the API refuses to
  delete a non-empty bucket. Run `oci os object bulk-delete` first.
- **No retention rules** (mutually exclusive with versioning).
- **No CORS argument** — the endpoint already returns a wildcard
  `access-control-allow-origin`.