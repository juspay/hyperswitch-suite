<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_artifact_registry_repository.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, integ, prod, sandbox) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels applied to every repository | `map(string)` | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Location for the repositories (region, e.g. europe-west1) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID where repositories are created | `string` | n/a | yes |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of repositories to create, keyed by repository\_id | <pre>map(object({<br/>    description    = optional(string)<br/>    format         = optional(string, "DOCKER")<br/>    mode           = optional(string, "STANDARD_REPOSITORY")<br/>    kms_key_name   = optional(string)<br/>    immutable_tags = optional(bool, false)<br/>    labels         = optional(map(string), {})<br/>    cleanup_policies = optional(map(object({<br/>      action               = optional(string, "DELETE")<br/>      most_recent_versions = optional(number)<br/>      condition = optional(object({<br/>        tag_state             = optional(string, "ANY")<br/>        tag_prefixes          = optional(list(string))<br/>        version_name_prefixes = optional(list(string))<br/>        package_name_prefixes = optional(list(string))<br/>        older_than            = optional(string)<br/>      }))<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_repository_iam"></a> [repository\_iam](#input\_repository\_iam) | Map of repository\_id to list of {role, member} IAM bindings to grant on that repository | <pre>map(list(object({<br/>    role   = string<br/>    member = string<br/>  })))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Map of repository key to its fully qualified ID |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of repository key to its repository\_id |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Map of repository key to its pull/push URL (<location>-docker.pkg.dev/<project>/<repo>) |
<!-- END_TF_DOCS -->
