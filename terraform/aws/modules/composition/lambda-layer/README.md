# Lambda Layer Module

Generic Terraform module that publishes an AWS Lambda Layer from a pre-built zip file.

Use this to bundle the Python dependencies that the other chaos-testing modules
need at runtime: `psycopg2` for the Aurora fault/stress Lambdas and `redis-py`
for the ElastiCache stress Lambdas.

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

## Building the layer zip

For a Python Lambda layer the zip must contain the installed package under a
top-level `python/` directory. Build it from an Amazon Linux 2 / 2023 compatible
environment so compiled extensions match the Lambda runtime:

```bash
# psycopg2 layer (used by aurora-fault-injection)
mkdir -p python
pip install psycopg2-binary --target python
zip -r psycopg2.zip python

# redis-py layer (used by elasticache-stress-test)
mkdir -p python
pip install redis --target python
zip -r redis-py.zip python
```

## How the layer is consumed

Publish the zip with this module, then pass the resulting `layer_arn` output to
the module that needs it via its `lambda_layers` input:

| Layer | Consumed by | Needed by |
|-------|-------------|-----------|
| `psycopg2` | `aurora-fault-injection` | fault-injection handlers and stress-test Lambdas |
| `redis-py` | `elasticache-stress-test` | `cpu_stress`, `memory_stress`, `mixed_workload`, `connection_exhaustion`, `connection_orchestrator`, `cleanup` |

```hcl
module "psycopg2_layer" {
  source       = "./terraform/aws/modules/composition/lambda-layer"
  layer_name   = "psycopg2"
  zip_path     = "${path.module}/psycopg2.zip"
}

module "aurora_fault_injection" {
  source        = "./terraform/aws/modules/composition/aurora-fault-injection"
  # ...
  lambda_layers = [module.psycopg2_layer.layer_arn]
}
```

Because `lambda_layers` is a list, you can also reference a layer published
independently (for example an account-wide `psycopg2` layer) by ARN instead of
deploying one with this module. Note the `elasticache-stress-test` `failover`
function uses only `boto3` and needs no layer.

See `outputs.tf` for the layer ARN and version outputs.