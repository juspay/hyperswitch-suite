<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_deployment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_integration.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_integration_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration_response) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_api_gateway_resource.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_lambda_permission.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_destination_arn"></a> [access\_log\_destination\_arn](#input\_access\_log\_destination\_arn) | ARN of the CloudWatch log group for API Gateway access logs | `string` | `null` | no |
| <a name="input_access_log_format"></a> [access\_log\_format](#input\_access\_log\_format) | Format of access logs for API Gateway | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the API Gateway | `string` | `"Managed by Terraform"` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | Endpoint type for the API Gateway (REGIONAL, EDGE, or PRIVATE) | `string` | `"REGIONAL"` | no |
| <a name="input_lambda_integrations"></a> [lambda\_integrations](#input\_lambda\_integrations) | List of Lambda integrations to create | <pre>list(object({<br/>    resource_path    = string<br/>    http_method      = string<br/>    lambda_arn       = string<br/>    integration_type = optional(string, "AWS_PROXY")<br/>  }))</pre> | `[]` | no |
| <a name="input_methods"></a> [methods](#input\_methods) | List of API methods to create | <pre>list(object({<br/>    resource_path      = string<br/>    http_method        = string<br/>    authorization      = optional(string, "NONE")<br/>    authorizer_id      = optional(string, null)<br/>    api_key_required   = optional(bool, false)<br/>    request_parameters = optional(map(string), {})<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the API Gateway | `string` | n/a | yes |
| <a name="input_resources"></a> [resources](#input\_resources) | List of API resources to create | <pre>list(object({<br/>    path_part   = string<br/>    parent_path = optional(string, "/") # Parent path, defaults to root<br/>  }))</pre> | `[]` | no |
| <a name="input_stage_description"></a> [stage\_description](#input\_stage\_description) | Description of the stage | `string` | `""` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Name of the API Gateway stage | `string` | `"default"` | no |
| <a name="input_stage_variables"></a> [stage\_variables](#input\_stage\_variables) | Map of stage variables | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_endpoint_ids"></a> [vpc\_endpoint\_ids](#input\_vpc\_endpoint\_ids) | List of VPC endpoint IDs for PRIVATE endpoint type | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | ID of the deployment |
| <a name="output_invoke_url"></a> [invoke\_url](#output\_invoke\_url) | URL to invoke the API at this stage |
| <a name="output_resource_ids"></a> [resource\_ids](#output\_resource\_ids) | Map of resource path to resource ID |
| <a name="output_rest_api_arn"></a> [rest\_api\_arn](#output\_rest\_api\_arn) | ARN of the REST API |
| <a name="output_rest_api_execution_arn"></a> [rest\_api\_execution\_arn](#output\_rest\_api\_execution\_arn) | Execution ARN of the REST API |
| <a name="output_rest_api_id"></a> [rest\_api\_id](#output\_rest\_api\_id) | ID of the REST API |
| <a name="output_rest_api_name"></a> [rest\_api\_name](#output\_rest\_api\_name) | Name of the REST API |
| <a name="output_rest_api_root_resource_id"></a> [rest\_api\_root\_resource\_id](#output\_rest\_api\_root\_resource\_id) | ID of the root resource |
| <a name="output_stage_arn"></a> [stage\_arn](#output\_stage\_arn) | ARN of the deployed stage |
| <a name="output_stage_name"></a> [stage\_name](#output\_stage\_name) | Name of the deployed stage |
<!-- END_TF_DOCS -->