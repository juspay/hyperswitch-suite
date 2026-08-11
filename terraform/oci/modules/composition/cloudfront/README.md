# cloudfront (OCI) — GAP MODULE, no direct equivalent

There is **no OCI CDN service with a Terraform resource** — OCI does not offer a general-purpose,
globally-distributed content-delivery PaaS comparable to CloudFront, Azure CDN, or Google Cloud CDN. This is a
real capability gap in OCI, not a naming difference.

## What this module does instead

It attaches **OCI Web Application Firewall** (`oci_waf_web_app_firewall`) to the origin load balancer — OCI's
closest managed *edge security* layer (L7 WAF rules, rate limiting, bot management), but it does **not** provide:

- Edge caching / PoPs (no reduction in origin latency for geographically distant users)
- CloudFront Functions / Lambda@Edge equivalents
- Signed URLs/cookies, origin access identity, or the S3-origin integration patterns from the AWS module

## Recommended options if edge caching/CDN is required

1. **Third-party CDN in front of the OCI Load Balancer** (Cloudflare, Fastly, Akamai, CacheFly, etc.) — the most
   common real-world pattern for OCI workloads that need CDN behavior; DNS points at the third-party CDN, which
   origin-pulls from the OCI LB.
2. **Varnish Enterprise on OCI** — Oracle has a published reference architecture for self-hosted Varnish-based
   caching on OCI compute if a self-managed edge cache is acceptable.
3. **Do without** if the workload (like most of Hyperswitch's payment-processing traffic) is API traffic that
   shouldn't be cached anyway — CloudFront may only be fronting a small static-asset surface in the AWS
   deployment, in which case an OCI Object Storage bucket with a public pre-authenticated request, or a small
   third-party CDN in front of it, covers the same need without needing this module at all.
