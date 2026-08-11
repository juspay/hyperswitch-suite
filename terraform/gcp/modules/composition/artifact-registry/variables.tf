variable "project_id" {
  description = "GCP project ID where repositories are created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "location" {
  description = "Location for the repositories (region, e.g. europe-west1)"
  type        = string
}

variable "repositories" {
  description = "Map of repositories to create, keyed by repository_id"
  type = map(object({
    description    = optional(string)
    format         = optional(string, "DOCKER")
    mode           = optional(string, "STANDARD_REPOSITORY")
    kms_key_name   = optional(string)
    immutable_tags = optional(bool, false)
    labels         = optional(map(string), {})
    cleanup_policies = optional(map(object({
      action               = optional(string, "DELETE")
      most_recent_versions = optional(number)
      condition = optional(object({
        tag_state             = optional(string, "ANY")
        tag_prefixes          = optional(list(string))
        version_name_prefixes = optional(list(string))
        package_name_prefixes = optional(list(string))
        older_than            = optional(string)
      }))
    })), {})
  }))
  default = {}
}

variable "repository_iam" {
  description = "Map of repository_id to list of {role, member} IAM bindings to grant on that repository"
  type = map(list(object({
    role   = string
    member = string
  })))
  default = {}
}

variable "labels" {
  description = "Additional labels applied to every repository"
  type        = map(string)
  default     = {}
}
