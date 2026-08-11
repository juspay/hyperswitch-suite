# terraform-backend (OCI)

OCI equivalent of `terraform/aws/modules/composition/terraform-backend`. Uses `oci_objectstorage_bucket` for state
storage. No verified registry module exists - raw `oci` provider resources.

## Using the bucket as a Terraform backend

OCI Object Storage exposes an **S3 Compatibility API**, so Terraform's built-in `s3` backend can point at it
directly — no custom backend plugin needed:

```hcl
terraform {
  backend "s3" {
    bucket = "<state_bucket_name>"
    key    = "envs/dev/terraform.tfstate"
    region = "us-ashburn-1" # any valid region string; ignored by OCI but required by the backend

    endpoints = {
      s3 = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum             = true
    use_path_style               = true
  }
}
```

Credentials are an OCI **Customer Secret Key** (`access_key`/`secret_key`, generated per-user in the OCI Console
under *Identity → Users → Customer Secret Keys*), not your OCI API signing key.

## State locking

Terraform >= 1.10's `s3` backend performs native conditional-write locking against any S3-compatible bucket,
including OCI's — **no separate lock table is needed** in the common case, unlike AWS where a DynamoDB table is
required. `create_lock_table` provisions an `oci_nosql_table` (OCI's closest DynamoDB analog) only for teams that
need locking support on Terraform < 1.10 or an external locking mechanism.
