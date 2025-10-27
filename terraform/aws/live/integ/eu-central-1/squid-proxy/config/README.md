# Squid Proxy Configuration Files

This directory contains configuration files that need to be uploaded to the S3 config bucket for the Squid proxy instances.

## Purpose

When Squid instances launch, they download configuration files from the S3 bucket specified in `config_bucket_name`. Place all necessary configuration files here.

## Typical Files

- `squid.conf` - Main Squid configuration
- `allowlist.txt` - Allowed domains/IPs
- `blocklist.txt` - Blocked domains/IPs
- `custom-acls.conf` - Custom ACL rules
- Any other Squid-specific configs

## Upload to S3

After creating/modifying files here, upload them to S3:

```bash
# Upload all files to the config bucket
aws s3 sync ./config/ s3://hyperswitch-dev-proxy-config-eu-central-1/squid/

# Or upload specific file
aws s3 cp ./config/squid.conf s3://hyperswitch-dev-proxy-config-eu-central-1/squid/squid.conf
```

## Userdata Integration

The userdata script (`templates/userdata.sh`) downloads these files during instance initialization:

```bash
# Example from userdata.sh
aws s3 cp s3://${CONFIG_BUCKET}/squid/squid.conf /etc/squid/squid.conf
```

## Environment-Specific Configs

Different environments can have different configurations:
- Dev: Permissive rules for testing
- Integ: Similar to prod, but with test domains allowed
- Prod: Strict security rules
