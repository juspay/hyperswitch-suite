<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_custom_role.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where custom roles are created | `string` | n/a | yes |
| <a name="input_roles"></a> [roles](#input\_roles) | Map of custom IAM roles to create, keyed by a DNS-safe logical name | <pre>map(object({<br/>    title       = string<br/>    description = string<br/>    permissions = list(string)<br/>    stage       = optional(string, "GA")<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_ids"></a> [role\_ids](#output\_role\_ids) | Map of logical name to the custom role's fully qualified ID |
| <a name="output_role_names"></a> [role\_names](#output\_role\_names) | Map of logical name to the custom role's role\_id (used in google\_project\_iam\_member.role) |
<!-- END_TF_DOCS -->
