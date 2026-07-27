# Lambda Layer Module

Generic Terraform module that publishes an AWS Lambda Layer from a pre-built zip file.

## What it creates

- `aws_lambda_layer_version` resource with optional source hash, runtime compatibility, license info, and tags

## Usage

```hcl
module "redis_py_layer" {
  source = "./terraform/aws/modules/composition/lambda-layer"

  layer_name          = "redis-py"
  description         = "redis-py library for Redis/Valkey Lambdas"
  zip_path            = "${path.module}/redis-py.zip"
  compatible_runtimes = ["python3.11"]

  tags = {
    Project = "my-project"
  }
}
```

## Required inputs

- `layer_name`
- `zip_path`

## Optional highlights

- `source_hash` — pre-computed Base64 SHA256 of the zip
- `compatible_runtimes` — defaults to `["python3.11"]`
- `license_info` — license string for the layer

See `variables.tf` and `outputs.tf` for full input/output listings.
