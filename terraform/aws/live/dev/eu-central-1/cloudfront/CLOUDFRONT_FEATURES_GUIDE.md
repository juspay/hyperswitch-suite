# CloudFront Configuration Features Guide

## Currently Configured ✅

### 1. Distributions (3)
- web-app, api-cdn, media-cdn
- ✅ Comments, enabled status, price class
- ✅ Default root object
- ✅ HTTP versions (HTTP/3, HTTP/2, HTTP/1.1)

### 2. Origins
- ✅ S3 origins with OAC
- ✅ ALB/Custom origins
- ❌ VPC Origins (new feature for private VPC resources)

### 3. Origin Access Controls (OAC)
- ✅ Custom OACs for S3 buckets
- ✅ Automatic bucket policy application

### 4. Response Headers Policies
- ✅ 3 Custom CORS policies
- Uses AWS-managed policies via templates

### 5. CloudFront Functions
- ✅ redirect-to-login
- ✅ add-security-headers

### 6. Cache Behaviors
- ✅ Default cache behavior
- ✅ Ordered cache behaviors with templates
- Uses AWS-managed cache policies

### 7. Invalidations
- ✅ Configured with versioning

## Missing/Optional Features 🔧

### 1. **Custom Cache Policies** ❌
Instead of using AWS-managed policies, you can create custom ones:

```yaml
cache_policies:
  - name: "hyperswitch-api-cache-policy"
    comment: "Custom cache policy for API with specific TTLs"
    min_ttl: 0
    default_ttl: 300
    max_ttl: 3600
    parameters_in_cache_key:
      enable_accept_encoding_gzip: true
      enable_accept_encoding_brotli: true
      query_strings_config:
        query_string_behavior: "whitelist"
        query_strings:
          - "api_key"
          - "version"
      headers_config:
        header_behavior: "whitelist"
        headers:
          - "Authorization"
          - "CloudFront-Viewer-Country"
      cookies_config:
        cookie_behavior: "none"
```

**When to use:**
- Need fine-grained control over what's included in cache keys
- Want to cache based on specific query strings/headers
- Need different TTL settings than AWS-managed policies

### 2. **Custom Origin Request Policies** ❌
Control what CloudFront forwards to origins:

```yaml
origin_request_policies:
  - name: "hyperswitch-api-origin-request"
    comment: "Custom origin request policy for API"
    query_strings_config:
      query_string_behavior: "all"
    headers_config:
      header_behavior: "whitelist"
      headers:
        - "Authorization"
        - "X-Forwarded-For"
        - "User-Agent"
    cookies_config:
      cookie_behavior: "all"
```

**When to use:**
- Need to forward specific headers to origin
- Want to control query string/cookie forwarding
- Different from AWS-managed policies

### 3. **WAF Web ACL** ❌
Add AWS WAF for security:

```yaml
distributions:
  web-app:
    web_acl_id: "arn:aws:wafv2:us-east-1:123456789012:global/webacl/hyperswitch-waf/..."
```

**When to use:**
- DDoS protection
- Rate limiting
- Geographic restrictions
- Bot protection
- SQL injection/XSS protection

### 4. **Custom SSL/TLS Certificates** ❌
Use ACM certificates for custom domains:

```yaml
distributions:
  web-app:
    aliases:
      - "cdn.hyperswitch.com"
      - "assets.hyperswitch.com"
    viewer_certificate:
      acm_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/..."
      ssl_support_method: "sni-only"
      minimum_protocol_version: "TLSv1.2_2021"
```

**When to use:**
- Custom domain names (not *.cloudfront.net)
- Brand consistency
- Production deployments

### 5. **Geographic Restrictions** ❌
Restrict access by country:

```yaml
distributions:
  web-app:
    geo_restriction:
      restriction_type: "whitelist"  # or "blacklist"
      locations:
        - "US"
        - "CA"
        - "GB"
        - "IN"
```

**When to use:**
- Compliance requirements
- Content licensing restrictions
- Regional service availability

### 6. **Lambda@Edge Functions** ❌
More powerful than CloudFront Functions:

```yaml
ordered_cache_behaviors:
  - path_pattern: "/api/v1/*"
    target_origin_id: "api-v1"
    lambda_function_associations:
      - event_type: "viewer-request"
        lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:auth-check:3"
        include_body: false
      - event_type: "origin-response"
        lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:transform:2"
        include_body: true
```

**When to use:**
- Complex authentication logic
- Request/response transformation
- A/B testing
- URL rewrites
- Access to network/file system

**Differences from CloudFront Functions:**
| Feature | CloudFront Functions | Lambda@Edge |
|---------|---------------------|-------------|
| Runtime | JavaScript subset | Node.js/Python |
| Execution time | <1ms | Up to 30s |
| Memory | N/A | 128MB - 10GB |
| Network access | ❌ | ✅ |
| External libraries | ❌ | ✅ |
| Cost | Cheaper | More expensive |
| Use case | Simple transforms | Complex logic |

### 7. **Logging to S3** ❌
Currently disabled in your setup:

```yaml
# In terraform.tfvars
enable_logging = true
create_log_bucket = true
```

**When to use:**
- Security auditing
- Analytics
- Debugging
- Compliance

### 8. **Real-time Logs (Kinesis)** ❌
Stream logs in real-time:

```yaml
distributions:
  web-app:
    realtime_log_config:
      name: "hyperswitch-realtime-logs"
      sampling_rate: 100  # 1-100
      kinesis_stream_arn: "arn:aws:kinesis:..."
      fields:
        - "timestamp"
        - "c-ip"
        - "cs-uri-stem"
        - "sc-status"
```

**When to use:**
- Real-time monitoring
- Immediate alerting
- Live dashboards

### 9. **Origin Failover** ❌
Automatic failover to backup origin:

```yaml
origins:
  - origin_id: "primary-alb"
    type: "alb"
    domain_name: "primary-alb.example.com"

  - origin_id: "backup-alb"
    type: "alb"
    domain_name: "backup-alb.example.com"

origin_groups:
  - origin_group_id: "api-failover-group"
    primary_member_origin_id: "primary-alb"
    secondary_member_origin_id: "backup-alb"
    failover_criteria:
      - 500
      - 502
      - 503
      - 504
```

**When to use:**
- High availability requirements
- Multi-region deployments
- Disaster recovery

### 10. **Field-Level Encryption** ❌
Encrypt specific fields end-to-end:

```yaml
field_level_encryption:
  - profile_name: "payment-data-encryption"
    comment: "Encrypt credit card data"
    public_key_id: "K2EXAMPLE"
    fields:
      - "credit_card_number"
      - "cvv"
```

**When to use:**
- PCI compliance
- Sensitive data protection
- End-to-end encryption

### 11. **Continuous Deployment (Blue/Green)** ❌
Test changes before full deployment:

```yaml
distributions:
  web-app:
    staging_distribution: true
```

**When to use:**
- Testing configuration changes
- Gradual rollouts
- A/B testing infrastructure

### 12. **Custom Error Pages** ✅ (Partially)
You have basic SPA routing, but can add more:

```yaml
custom_error_responses:
  - error_code: 403
    error_caching_min_ttl: 300
    response_code: 200
    response_page_path: "/index.html"
  - error_code: 500
    error_caching_min_ttl: 0
    response_code: 500
    response_page_path: "/errors/500.html"
  - error_code: 503
    error_caching_min_ttl: 0
    response_code: 503
    response_page_path: "/errors/maintenance.html"
```

### 13. **Origin Shield** ❌
Additional caching layer to reduce origin load:

```yaml
origins:
  - origin_id: "api-v1"
    type: "alb"
    domain_name: "..."
    origin_shield:
      enabled: true
      origin_shield_region: "eu-central-1"
```

**When to use:**
- High traffic to single origin
- Reduce origin costs
- Improve cache hit ratio

### 14. **Trusted Key Groups (Signed URLs/Cookies)** ❌
Restrict access to content:

```yaml
distributions:
  media-cdn:
    default_cache_behavior:
      trusted_key_groups:
        - "hyperswitch-video-access-keys"
```

**When to use:**
- Private content (videos, documents)
- Time-limited access
- Per-user authorization

### 15. **Monitoring & Alarms** ❌
CloudWatch alarms for distribution health:

```yaml
monitoring:
  alarms:
    - name: "high-error-rate"
      metric: "4xxErrorRate"
      threshold: 5  # percent
      evaluation_periods: 2
    - name: "origin-latency"
      metric: "OriginLatency"
      threshold: 1000  # ms
      evaluation_periods: 3
```

## Recommended Configuration Priority

### For Production (Priority Order):

1. **🔴 Critical:**
   - Custom SSL/TLS certificates (for custom domains)
   - WAF Web ACL (security)
   - S3 logging (compliance/debugging)
   - Geographic restrictions (if needed for compliance)

2. **🟡 Important:**
   - Custom Cache Policies (performance tuning)
   - Origin Failover (high availability)
   - CloudWatch alarms (monitoring)
   - Lambda@Edge (if complex auth needed)

3. **🟢 Nice to Have:**
   - Origin Shield (cost optimization)
   - Real-time logs (advanced monitoring)
   - Continuous deployment (safer updates)
   - Field-level encryption (sensitive data)

### For Your Dev Environment:

Currently, you're using **AWS-managed policies**, which is **perfectly fine for development and even production** if they meet your needs!

**Consider adding:**
1. ✅ S3 logging (already configured, just enable it)
2. ✅ Custom domain + ACM certificate (when ready for dev.hyperswitch.com)
3. ✅ WAF (for security testing)

## Current Architecture is Good! ✅

Your current setup is already well-architected:
- ✅ Multiple distributions for different purposes
- ✅ OAC for S3 security
- ✅ Custom response headers policies for CORS
- ✅ CloudFront Functions for lightweight transforms
- ✅ Template-based configuration for reusability
- ✅ Using AWS-managed policies (reduces complexity)

You don't **need** custom cache/origin request policies unless AWS-managed ones don't fit your requirements.
