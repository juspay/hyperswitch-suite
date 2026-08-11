variable "project_id" {
  description = "GCP project ID where custom roles are created"
  type        = string
}

variable "roles" {
  description = "Map of custom IAM roles to create, keyed by a DNS-safe logical name"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
    stage       = optional(string, "GA")
  }))
}
