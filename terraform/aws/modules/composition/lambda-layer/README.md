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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lambda_layer_version.layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_compatible_runtimes"></a> [compatible\_runtimes](#input\_compatible\_runtimes) | List of compatible Lambda runtimes | `list(string)` | <pre>[<br/>  "python3.11"<br/>]</pre> | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Lambda layer | `string` | `""` | no |
| <a name="input_layer_name"></a> [layer\_name](#input\_layer\_name) | Name of the Lambda layer | `string` | n/a | yes |
| <a name="input_license_info"></a> [license\_info](#input\_license\_info) | License information for the layer | `string` | `""` | no |
| <a name="input_source_hash"></a> [source\_hash](#input\_source\_hash) | Base64-encoded SHA256 hash of the zip file | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the layer | `map(string)` | `{}` | no |
| <a name="input_zip_path"></a> [zip\_path](#input\_zip\_path) | Path to the layer zip file | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_layer_arn"></a> [layer\_arn](#output\_layer\_arn) | ARN of the Lambda layer (with version) |
| <a name="output_layer_name"></a> [layer\_name](#output\_layer\_name) | Name of the Lambda layer |
| <a name="output_layer_version_arn"></a> [layer\_version\_arn](#output\_layer\_version\_arn) | ARN of the Lambda layer version |
| <a name="output_source_code_hash"></a> [source\_code\_hash](#output\_source\_code\_hash) | Hash of the layer source code |
| <a name="output_version"></a> [version](#output\_version) | Version number of the Lambda layer |
<!-- END_TF_DOCS -->