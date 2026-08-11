variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "file_systems" {
  description = "Map of file-system key -> config. Equivalent of AWS var.file_systems."
  type = map(object({
    display_name           = string
    availability_domain    = string # OCI FSS file systems are AD-local (unlike EFS, which is regional)
    kms_key_id             = optional(string)
    mount_target_subnet_id = string
    mount_target_nsg_ids   = optional(list(string), [])
    export_path            = optional(string, "/export")
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
