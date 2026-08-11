variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "repositories" {
  description = "Map of repository key -> config. Equivalent of AWS var.repositories."
  type = map(object({
    name         = string
    is_immutable = optional(bool, false)
    is_public    = optional(bool, false)
  }))
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
