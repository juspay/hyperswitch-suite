# CloudFront CDN Configuration - Live Layer

## Overview

This directory contains YAML-driven CloudFront configuration with reusable behavior templates. Manage multiple CDN distributions from a single configuration file.

## Quick Start

### 1. Configure Distribution

Edit `config.yaml`:

```yaml
distributions:
  web-app:
    comment: "Web application CDN"

    origins:
      - origin_id: "s3-assets"
        type: "s3"
        s3_bucket_id: "your-bucket"
        s3_bucket_arn: "arn:aws:s3:::your-bucket"
        origin_access_control_id: "your-oac"
        apply_bucket_policy: true

    default_cache_behavior:
      target_origin_id: "s3-assets"
      allowed_methods: ["GET", "HEAD"]
      cached_methods: ["GET", "HEAD"]
      viewer_protocol_policy: "redirect-to-https"
      ttl:
        min_ttl: 0
        default_ttl: 3600
        max_ttl: 86400

    invalidation:
      enabled: true
      version: "v1.0.0"  # Change to trigger invalidation
      paths: ["/*"]
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. Invalidate Cache

```bash
# Update version in config.yaml
invalidation:
  version: "v1.0.1"  # Increment version
  paths: ["/*"]

terraform apply
```

## Configuration Reference

### Behavior Templates

Pre-built templates for common use cases:

- **`static_assets`** - CSS/JS/images (aggressive caching, 1 year TTL)
- **`api`** - REST APIs (minimal caching, CORS enabled)
- **`admin`** - Admin panels (no caching)
- **`media`** - Videos/audio (long TTL, no compression)
- **`api_v2`** - Newer APIs with specific caching

**Using templates:**

```yaml
ordered_cache_behaviors:
  - template: "static_assets"
    path_pattern: "/css/*"
    target_origin_id: "s3-assets"

  - template: "api"
    path_pattern: "/api/*"
    target_origin_id: "api-origin"
```

**Custom behavior (no template):**

```yaml
- path_pattern: "/custom/*"
  target_origin_id: "custom-origin"
  allowed_methods: ["GET", "POST"]
  viewer_protocol_policy: "redirect-to-https"
  ttl: { min_ttl: 0, default_ttl: 300, max_ttl: 3600 }
```

### Origins

**S3 Origin:**

```yaml
origins:
  - origin_id: "s3-assets"
    type: "s3"
    s3_bucket_id: "bucket-name"
    s3_bucket_arn: "arn:aws:s3:::bucket-name"
    origin_access_control_id: "oac-name"  # Reference OAC
    apply_bucket_policy: true
```

**ALB Origin:**

```yaml
origins:
  - origin_id: "api-alb"
    type: "alb"
    domain_name: "alb-123.us-east-1.elb.amazonaws.com"
    custom_origin_config:
      http_port: 80
      https_port: 443
      origin_protocol_policy: "https-only"
```

### Custom Domains

**Prerequisites:**
- ACM certificate in us-east-1
- DNS CNAME records

**Configuration:**

```yaml
web-app:
  aliases:
    - "example.com"
    - "*.example.com"

  viewer_certificate:
    acm_certificate_arn: "arn:aws:acm:us-east-1:123:certificate/..."
    ssl_support_method: "sni-only"
```

### Origin Access Control (OAC)

**Define OAC:**

```yaml
origin_access_controls:
  - name: "my-oac"
    description: "OAC for S3 bucket"
    origin_access_control_origin_type: "s3"
    signing_behavior: "always"
    signing_protocol: "sigv4"
```

**Reference in origin:**

```yaml
origins:
  - origin_id: "s3-assets"
    type: "s3"
    origin_access_control_id: "my-oac"
    apply_bucket_policy: true
```

### CloudFront Functions

**Define function:**

```yaml
cloudfront_functions:
  - name: "redirect-to-login"
    runtime: "cloudfront-js-1.0"
    code: |
      function handler(event) {
          var request = event.request;
          if (!request.headers.authorization) {
              return {
                  statusCode: 302,
                  headers: { location: { value: '/login.html' } }
              };
          }
          return request;
      }
    publish: true
```

**Associate with behavior:**

```yaml
ordered_cache_behaviors:
  - path_pattern: "/api/*"
    function_associations:
      - event_type: "viewer-request"
        function_arn: "redirect-to-login"
```

### Response Headers Policies

```yaml
response_headers_policies:
  - name: "api-cors"
    cors_config:
      access_control_allow_credentials: true
      access_control_allow_headers:
        items: ["Authorization", "Content-Type"]
      access_control_allow_methods:
        items: ["GET", "POST", "PUT"]
      access_control_allow_origins:
        items: ["https://example.com"]
```

### Invalidation Options

**Selective paths:**

```yaml
invalidation:
  version: "v1.0.1"
  paths:
    - "/css/*"          # Only CSS
    - "/js/*"           # Only JS
    - "/index.html"     # Only HTML
```

**Disable invalidation:**

```yaml
invalidation:
  enabled: false  # No invalidation
```

**Multiple distributions** (each has own invalidation):

```yaml
distributions:
  web-app:
    invalidation:
      version: "v1.2.3"
      paths: ["/*"]

  api-cdn:
    invalidation:
      version: "v1.5.0"
      paths: ["/api/*"]
```

## Key Features

- Template-driven cache behaviors (reduce duplication)
- YAML-based configuration (version-controllable)
- Multiple distributions per environment
- Custom domain support (CNAMEs + ACM SSL)
- OAC for secure S3 access
- CloudFront Functions for auth/security
- Automated cache invalidation
- Custom CORS & security policies
- Path-based routing to different origins

## Common Use Cases

### Single Page Application (SPA)

```yaml
web-app:
  default_cache_behavior:
    target_origin_id: "s3-assets"
    ttl: { min_ttl: 0, default_ttl: 0, max_ttl: 0 }

  custom_error_responses:
    - error_code: 404
      response_code: 200
      response_page_path: "/index.html"
```

### API CDN with Authentication

```yaml
api-cdn:
  default_cache_behavior:
    target_origin_id: "api-alb"
    allowed_methods: ["GET", "POST", "PUT", "DELETE"]
    ttl: { min_ttl: 0, default_ttl: 300, max_ttl: 3600 }

  ordered_cache_behaviors:
    - template: "api"
      path_pattern: "/api/*"
      target_origin_id: "api-alb"
```

### Multi-Origin Distribution

```yaml
multi-origin:
  origins:
    - origin_id: "static"
      type: "s3"
    - origin_id: "api"
      type: "alb"

  ordered_cache_behaviors:
    - template: "static_assets"
      path_pattern: "/static/*"
      target_origin_id: "static"

    - template: "api"
      path_pattern: "/api/*"
      target_origin_id: "api"
```

## AWS-Managed Policies Reference

**Cache Policies:**
- `Managed-CachingOptimized` - Static content (aggressive caching)
- `Managed-CachingDisabled` - Dynamic content (no caching)

**Origin Request Policies:**
- `Managed-AllViewer` - Forward all headers/cookies/query strings
- `Managed-CORS-S3Origin` - Minimal forwarding for CORS

**Response Headers Policies:**
- `Managed-SecurityHeadersPolicy` - HSTS, X-Frame-Options, XSS Protection
- `Managed-CORS-with-preflight-and-SecurityHeadersPolicy` - CORS + Security

## Troubleshooting

### Issue: S3 bucket shows public access
**Solution:** Configure OAC with `apply_bucket_policy: true`

### Issue: Invalidation not triggering
**Solution:** Change `version` field (Terraform detects change)

### Issue: Custom domain not working
**Solution:** Ensure ACM cert in us-east-1 + DNS CNAME records

### Issue: CORS errors
**Solution:** Add CORS config to response_headers_policies


## Best Practices

1. **Use templates** for common patterns (reduces duplication)
2. **Selective invalidation** (avoid `/*` when possible)
3. **Version invalidations** (v1.0.0, v1.0.1, etc.)
4. **Short TTLs for APIs** (5-10 minutes)
5. **Long TTLs for static** (1 day to 1 year)
6. **OAC for S3** (never use public access)
7. **Monitor invalidation history** (max 1000 per distribution)

## Support

- AWS CloudFront Docs: https://docs.aws.amazon.com/cloudfront/
- Terraform Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution